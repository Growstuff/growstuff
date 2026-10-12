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

  Event = Struct.new(:member, :verb, :subject, :at, :following, keyword_init: true)
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
    @growing ||= member.plantings.current.includes(:crop, :garden, :photos).order(planted_at: :desc).to_a
  end

  # Plantings we expect to have something to pick by now.
  def ready
    @ready ||= growing.select(&:harvest_time?)
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

  # Kilograms harvested in each month of this year and of last year.
  def harvest_by_month
    @harvest_by_month ||= (1..12).map do |month|
      { month:, this_year: monthly_kilograms[[0, month]] || 0, last_year: monthly_kilograms[[1, month]] || 0 }
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
    @activity ||= (events_for(followed_ids, following: true) + events_for(nearby_ids, following: false))
                  .uniq { |event| [event.member, event.verb, event.subject] }
                  .first(limit)
  end

  # The most planted and harvested crops this month and the next two, by
  # gardeners in the same band of latitude, in any year.
  def at_latitude(months: 3)
    return unless located?

    Rails.cache.fetch(['at-latitude', band, @today.month, @today.year], expires_in: 6.hours) do
      (0...months).map { |offset| month_leaders((@today.month - 1 + offset) % 12 + 1) }
    end
  end

  # Ten degrees of latitude centred, to the nearest five, on the member.
  def band
    @band ||= begin
      centre = (member.latitude / LATITUDE_BAND).round * LATITUDE_BAND
      (centre - LATITUDE_BAND..centre + LATITUDE_BAND)
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

    ids = sowing_candidates.pluck(:crop_id) - dismissed_crop_ids - growing.map(&:crop_id)
    crops = Crop.approved.where(id: ids).index_by(&:id)
    ids.filter_map { |id| crops[id] }.first(limit)
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

  private

  def year_range(years_back)
    start = @today.beginning_of_year - years_back.years
    start..start.end_of_year
  end

  def kilograms(years_back)
    member.harvests.where(harvested_at: year_range(years_back)).sum(:si_weight).to_f.round
  end

  def monthly_kilograms
    @monthly_kilograms ||= [0, 1].each_with_object({}) do |back, totals|
      member.harvests.where(harvested_at: year_range(back)).group("EXTRACT(MONTH FROM harvested_at)::int").sum(:si_weight).each do |month, kilos|
        totals[[back, month]] = kilos.to_f
      end
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

  def followed_ids
    @followed_ids ||= member.followed.pluck(:id)
  end

  def nearby_ids
    return [] unless located?

    @nearby_ids ||= Member.located.near([member.latitude, member.longitude], NEARBY_KM, units: :km)
                          .where.not(id: member.id).reorder(nil).limit(40).pluck(:id) - followed_ids
  end

  def events_for(ids, following:)
    return [] if ids.empty?

    events = Planting.where(owner_id: ids).includes(:owner, :crop).order(planted_at: :desc).limit(10).map do |planting|
      Event.new(member: planting.owner, verb: 'planted', subject: planting.crop, at: planting.planted_at, following:)
    end
    events += Harvest.where(owner_id: ids).includes(:owner, :crop).order(harvested_at: :desc).limit(10).map do |harvest|
      Event.new(member: harvest.owner, verb: 'harvested', subject: harvest.crop, at: harvest.harvested_at, following:)
    end
    events += Seed.current.tradable.where(owner_id: ids).includes(:owner, :crop).order(created_at: :desc).limit(5).map do |seed|
      Event.new(member: seed.owner, verb: 'has seeds to trade:', subject: seed.crop, at: seed.created_at, following:)
    end
    events.compact.sort_by { |event| event.at || Time.zone.at(0) }.reverse
  end

  def month_leaders(month)
    {
      month:,
      planting: leaders(Planting, :planted_at, month),
      harvesting: leaders(Harvest, :harvested_at, month)
    }
  end

  def leaders(model, date_column, month, limit = 3)
    scope = model.joins(:crop)
    scope = model == Planting ? scope.joins(:garden) : scope.joins(planting: :garden)
    scope.where(gardens: { latitude: band })
         .where("EXTRACT(MONTH FROM #{model.table_name}.#{date_column}) = ?", month)
         .group('crops.id', 'crops.name').order(Arel.sql('COUNT(*) DESC')).limit(limit).count
         .map { |(crop_id, name), count| { crop_id:, name:, count: } }
  end
end
