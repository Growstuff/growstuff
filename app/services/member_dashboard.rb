# frozen_string_literal: true

# What a signed-in member sees on the home page: their own garden's numbers,
# what is ready, and what gardeners at their latitude are doing this month.
#
# How much of it we show depends on how much they have recorded, so #stage
# tells the views whether this is someone's first visit, their first year of
# data, or years of it.
class MemberDashboard
  NEARBY_KM = 150
  LATITUDE_BAND = 5

  Comparison = Struct.new(:crop, :text, keyword_init: true)

  attr_reader :member

  def initialize(member, today: Time.zone.today)
    @member = member
    @today = today
  end

  # :new (nothing planted yet), :novice (first year of data), :veteran.
  def stage
    @stage ||= if first_planted_on.nil?
                 :new
               elsif first_planted_on > 1.year.ago.to_date
                 :novice
               else
                 :veteran
               end
  end

  def first_planted_on
    return @first_planted_on if defined?(@first_planted_on)

    @first_planted_on = member.plantings.minimum(:planted_at)&.to_date
  end

  def years_growing
    return unless first_planted_on

    [((@today - first_planted_on) / 365.25).floor, 1].max
  end

  def located?
    member.latitude.present?
  end

  def gardens
    @gardens ||= member.gardens.active.order_by_name.to_a
  end

  def growing
    @growing ||= member.plantings.current.includes({ crop: :parent }, :garden, :photos).order(planted_at: :desc).to_a
  end

  # Plantings we expect to have something to pick by now.
  def ready
    @ready ||= growing.select(&:harvest_time?)
  end

  # What they could record a harvest from: what is growing, with what is
  # ready to pick first.
  def harvest_choices
    ready + (growing - ready)
  end

  def beds
    counts = growing.group_by(&:garden_id)
    gardens.map do |garden|
      plantings = counts.fetch(garden.id, [])
      { garden:, plantings: plantings.size, ready: plantings.count { |planting| ready.include?(planting) } }
    end
  end

  def plantings_this_year
    member.plantings.where(planted_at: year_range(0)).count
  end

  def plantings_last_year
    member.plantings.where(planted_at: year_range(1)).count
  end

  def harvests_this_year
    member.harvests.where(harvested_at: year_range(0)).count
  end

  def harvests_last_year
    member.harvests.where(harvested_at: year_range(1)).count
  end

  def kilograms_this_year
    kilograms(0)
  end

  def kilograms_last_year
    kilograms(1)
  end

  def seed_varieties
    @seed_varieties ||= member.seeds.current.group(:crop_id).count.size
  end

  # Seed packets grouped by crop, biggest stash first.
  def seeds_on_hand(limit = 3)
    member.seeds.current.includes(:crop, :photos).group_by(&:crop).sort_by { |_crop, seeds| -seeds.size }.first(limit)
  end

  # Harvests and kilograms in each month of this year and of last year. Many
  # harvests are recorded without a weight, so the counts are the fuller picture.
  def harvest_by_month
    @harvest_by_month ||= (1..12).map do |month|
      {
        month:,
        harvests:  { this_year: monthly_totals[[0, month]][:count], last_year: monthly_totals[[1, month]][:count] },
        kilograms: { this_year: monthly_totals[[0, month]][:kilograms], last_year: monthly_totals[[1, month]][:kilograms] }
      }
    end
  end

  # Crops they have grown in both this year and last, and how this year went.
  def compared_with_last_year(limit = 3)
    both = crop_ids_planted_in(0) & crop_ids_planted_in(1)
    both.filter_map { |crop_id| sowing_comparison(crop_id) }.first(limit)
  end

  # The crops they planted in the month either side of this date last year,
  # most planted first.
  def planted_this_time_last_year(limit = 5)
    around = @today - 1.year
    member.plantings.where(planted_at: (around - 30.days)..(around + 30.days))
      .joins(:crop).group('crops.name').order(Arel.sql('COUNT(*) DESC'), 'crops.name').limit(limit).count.keys
  end

  # People they follow first, then people nearby.
  def activity(limit = 6)
    @activity ||= (RecentActivity.events(followed_ids, following: true) + RecentActivity.events(nearby_ids, following: false))
      .uniq { |event| [event.member, event.verb, event.subject] }
      .first(limit)
  end

  # The most planted and harvested crops this month and the next two, by
  # gardeners in the same band of latitude, in any year.
  def at_latitude(months: 3)
    return unless located?

    Rails.cache.fetch(['at-latitude', band, @today.month, @today.year], expires_in: 6.hours) do
      (0...months).map { |offset| month_leaders(((@today.month - 1 + offset) % 12) + 1) }
    end
  end

  # Ten degrees of latitude centred, to the nearest five, on the member.
  def band
    @band ||= begin
      centre = (member.latitude / LATITUDE_BAND).round * LATITUDE_BAND
      ((centre - LATITUDE_BAND)..(centre + LATITUDE_BAND))
    end
  end

  # Crops gardeners at this latitude are planting this month, most planted
  # first, leaving out what the member is already growing or has said is not
  # for them.
  def suggestions_enabled?
    member.suggest_crops
  end

  def easy_to_sow(limit = 3)
    return [] unless suggestions_enabled?

    crops_from(sowing_candidates, limit)
  end

  # The crops gardeners within NEARBY_KM of the member plant in any of the months, in any year, most planted first, leaving
  # out what the member is growing or has said is not for them. For a season's months.
  def sowing_in(months, limit = 12)
    return [] unless suggestions_enabled? && located?

    candidates = Rails.cache.fetch(['sowing-near', *WeatherReading.grid_point(member.latitude, member.longitude), months, @today.year],
                                   expires_in: 6.hours) do
      leaders(Planting, :planted_at, months, 40, gardens: { id: nearby_garden_ids })
    end
    crops_from(candidates, limit, leave_out_growing: false)
  end

  # The ids of the crops gardeners within NEARBY_KM have planted, counting a variety as planting its parent crop.
  def crop_ids_planted_nearby
    return [] unless located?

    crop_ids_of(Planting.where(garden_id: nearby_garden_ids))
  end

  # The same for the people the member follows.
  def crop_ids_planted_by_followed
    crop_ids_of(Planting.where(owner_id: followed_ids))
  end

  # The same for the member's own plantings, in any year.
  def crop_ids_planted
    crop_ids_of(member.plantings)
  end

  # The ids of the crops the member has seeds of that aren't used up, counting a variety's seeds as seeds of its parent crop.
  def crop_ids_with_seeds
    crop_ids_of(member.seeds.active)
  end

  # Whether the member has a planting growing of the crop, or of a variety of it.
  def growing?(crop)
    @growing_crop_ids ||= growing.flat_map { |planting| [planting.crop_id, planting.crop.parent_id] }.compact.to_set
    @growing_crop_ids.include?(crop.id)
  end

  # { crop id => the years before this one the member planted it in, oldest first }, for the crops given, counting a variety of
  # a crop as growing it. Crops they have not planted in an earlier year are left out.
  def grown_in_past(crop_ids)
    return {} if crop_ids.empty?

    rows = member.plantings.joins(:crop).where(plantings: { planted_at: ...@today.beginning_of_year })
      .where('plantings.crop_id IN (:ids) OR crops.parent_id IN (:ids)', ids: crop_ids)
      .pluck('plantings.crop_id', 'crops.parent_id', 'plantings.planted_at')
    rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(crop_id, parent_id, planted_at), found|
      [crop_id, parent_id].compact.select { |id| crop_ids.include?(id) }.each { |id| found[id] |= [planted_at.year] }
    end.transform_values(&:sort)
  end

  # { crop id => login names of the people the member follows who have it growing }, for the crops given, counting a variety
  # of a crop as growing it. Crops no one they follow is growing are left out.
  def followed_growing(crop_ids)
    return {} if crop_ids.empty? || followed_ids.empty?

    rows = Planting.current.joins(:crop).where(owner_id: followed_ids)
      .where('plantings.crop_id IN (:ids) OR crops.parent_id IN (:ids)', ids: crop_ids)
      .distinct.pluck('plantings.crop_id', 'crops.parent_id', 'members.login_name')
    rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(crop_id, parent_id, name), found|
      [crop_id, parent_id].compact.select { |id| crop_ids.include?(id) }.each { |id| found[id] |= [name] }
    end
  end

  def dismissed_count
    dismissed_crop_ids.size
  end

  def suggested_crop
    easy_to_sow(1).first
  end

  def band_label
    low, high = [band.begin.abs, band.end.abs].minmax
    "#{low}–#{high}°#{member.latitude.negative? ? 'S' : 'N'}"
  end

  def jobs_today_or_tomorrow?
    jobs_today_or_tomorrow_count.positive?
  end

  def jobs_today_or_tomorrow_count
    @jobs_today_or_tomorrow_count ||= member.jobs.active.where(due_date: @today..(@today + 1.day)).count
  end

  private

  # The crops of the candidates, in their order, without those dismissed, and without those growing unless they are to show.
  def crops_from(candidates, limit, leave_out_growing: true)
    ids = candidates.pluck(:crop_id) - dismissed_crop_ids
    ids -= growing.map(&:crop_id) if leave_out_growing
    crops = Crop.approved.where(id: ids).index_by(&:id)
    ids.filter_map { |id| crops[id] }.first(limit)
  end

  def year_range(years_back)
    start = @today.beginning_of_year - years_back.years
    start..start.end_of_year
  end

  def kilograms(years_back)
    member.harvests.where(harvested_at: year_range(years_back)).sum(:si_weight).to_f.round
  end

  def monthly_totals
    @monthly_totals ||= begin
      totals = Hash.new { |hash, key| hash[key] = { count: 0, kilograms: 0.0 } }
      [0, 1].each do |back|
        harvested = member.harvests.where(harvested_at: year_range(back)).group('EXTRACT(MONTH FROM harvested_at)::int')
        harvested.count.each { |month, count| totals[[back, month]][:count] = count }
        harvested.sum(:si_weight).each { |month, kilos| totals[[back, month]][:kilograms] = kilos.to_f }
      end
      totals
    end
  end

  def crop_ids_planted_in(years_back)
    member.plantings.where(planted_at: year_range(years_back)).distinct.pluck(:crop_id)
  end

  def sowing_comparison(crop_id)
    this_year = member.plantings.where(crop_id:, planted_at: year_range(0)).minimum(:planted_at)
    last_year = member.plantings.where(crop_id:, planted_at: year_range(1)).minimum(:planted_at)
    days = this_year.yday - last_year.yday
    return if days.zero?

    name = Crop.find(crop_id).name.capitalize
    Comparison.new(crop: name, text: "sown #{pluralize_days(days.abs)} #{days.negative? ? 'earlier' : 'later'} than last year")
  end

  def pluralize_days(count)
    count == 1 ? '1 day' : "#{count} days"
  end

  def dismissed_crop_ids
    @dismissed_crop_ids ||= member.crop_dismissals.pluck(:crop_id)
  end

  def sowing_candidates
    return [] unless located?

    Rails.cache.fetch(['sowing-candidates', band, @today.month, @today.year], expires_in: 6.hours) do
      leaders(Planting, :planted_at, @today.month, 40)
    end
  end

  # The ids of the crops of the plantings or seeds, and of their parent crops.
  def crop_ids_of(records)
    records.joins(:crop).distinct.pluck('crops.id', 'crops.parent_id').flatten.compact.uniq
  end

  def followed_ids
    @followed_ids ||= member.followed.pluck(:id)
  end

  def nearby_ids
    return [] unless located?

    @nearby_ids ||= Member.located.near([member.latitude, member.longitude], NEARBY_KM, units: :km)
      .where.not(id: member.id).reorder(nil).limit(40).pluck(:id) - followed_ids
  end

  # The gardens, other than nurseries, within NEARBY_KM of the member.
  def nearby_garden_ids
    Garden.located_for_weather.near([member.latitude, member.longitude], NEARBY_KM, units: :km).reorder(nil).pluck(:id)
  end

  def month_leaders(month)
    {
      month:,
      planting:   leaders(Planting, :planted_at, month),
      harvesting: leaders(Harvest, :harvested_at, month)
    }
  end

  # month: a month number, or several.
  def leaders(model, date_column, month, limit = 3, gardens: { latitude: band })
    scope = model.joins(:crop)
    scope = model == Planting ? scope.joins(:garden) : scope.joins(planting: :garden)
    scope.where(gardens:)
      .where("EXTRACT(MONTH FROM #{model.table_name}.#{date_column}) IN (?)", Array(month))
      .group('crops.id', 'crops.name').order(Arel.sql('COUNT(*) DESC')).limit(limit).count
      .map { |(crop_id, name), count| { crop_id:, name:, count: } }
  end
end
