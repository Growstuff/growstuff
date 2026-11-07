# frozen_string_literal: true

# How a planting sits against the frost danger of its place: the usual and the possible frost danger dates around it,
# what the planting went through, and a verdict for the day. It holds the working out for the frost section of the
# planting page, and no text, so the page only has to draw it.
#
# The usual dates are the medians of past years and the possible ones are the earliest and latest it has come: see
# FrostStat. Approximate, regional and experimental.
class PlantingFrost
  # A stretch of the timeline. kind is :usual or :possible for frost danger, and :so_far, :still_to_come or :finished
  # for the planting, with :frost_safe for the days it was somewhere safe from frost. last is where the band really ends.
  Band = Struct.new(:kind, :from, :to, :last) do
    # Whether the timeline cuts the band off before its real end.
    def open?
      !last.nil? && last > to
    end
  end

  THRESHOLD_C = FrostCalculator::FROST_DANGER_C
  SOON_DAYS = 60
  YEAR_DAYS = 365

  attr_reader :crop_name, :planted_on, :sown_on, :safe_place, :ends_on, :today

  def finished?
    @finished
  end

  # Whether the planting has an expected end still to come. A perennial, or a crop with no lifespan known, has none, and
  # one that has outlived its expected end has none ahead.
  def end_ahead?
    !finished? && @expected_end && ends_on > today
  end

  # Whether the planting has lived longer than a frost year. The season it went in during is long gone, so what matters is
  # the latest year of its life: the current season while it grows.
  def long_lived?
    age_end - @planted_on > YEAR_DAYS
  end

  # Whether today is a day on the timeline worth marking: a planting still growing, and today inside the axis.
  def show_today?
    !finished? && axis.cover?(today)
  end

  # The typical frost-free days of the place, from the frost dates, or nil when they have none.
  def frost_free_days
    @stat.frost_free_days_median&.round
  end

  # readings: the planting's weather, as WeatherReading rows with temp_min_c.
  def self.for(planting, readings:, today: Time.zone.today)
    stat = planting.frost_danger
    return if stat.nil? || stat.unknown?

    # A finished planting with no finish date goes by its predicted finish, for the frost display only.
    return if planting.garden.frost_safe?

    stay = planting.frost_safe_stay
    new(stat:, crop_name: planting.crop.name, planted_on: stay&.ended_on || planting.planted_at,
        sown_on: (planting.planted_at if stay), safe_place: stay&.garden&.name,
        ends_on: planting.finished_at || planting.weather_due_on, finished: planting.finished?, readings:, today:)
  end

  # planted_on is the day frost danger starts for the planting: the day it went outdoors, if it began somewhere safe from
  # frost (a nursery, a greenhouse, indoors), and then sown_on is the day it was sown there and safe_place its name.
  def initialize(stat:, crop_name:, planted_on:, ends_on:, finished:, readings:, today:, sown_on: nil, safe_place: nil) # rubocop:disable Metrics/ParameterLists
    @stat = stat
    @sown_on = sown_on
    @safe_place = safe_place
    @crop_name = crop_name
    @planted_on = planted_on
    @finished = finished
    @readings = readings
    @today = today
    @expected_end = !ends_on.nil?
    @ends_on = ends_on || (finished ? planted_on : today)
  end

  # Whether the planting spent its first days somewhere safe from frost.
  def from_frost_safe?
    !sown_on.nil? && sown_on < planted_on
  end

  # Whether the planting has finished, nobody said when, and there is no predicted finish either, so we can't say what
  # it went through.
  def end_unknown?
    finished? && !@expected_end
  end

  # What to tell the member today. A planting that has finished is judged on what it went through, one still growing
  # on where today falls in the frost danger season of the year it went in.
  def verdict
    return :rare unless @stat.dated?
    return :finished_undated if end_unknown?
    return frost_nights.zero? ? :finished_clear : :finished_hit if @finished

    if @today < usual.first then :before_season
    elsif @today <= usual.last then :in_season
    elsif @today <= possible.last then :late_possible
    else :passed
    end
  end

  # The usual frost danger of the year the planting went in, from the median first frost to the median last.
  def usual
    @usual ||= season_dates(year, :first_frost_median, :last_frost_median)
  end

  # The earliest and the latest it has come in that year's place.
  def possible
    @possible ||= season_dates(year, :first_frost_p10, :last_frost_p90)
  end

  def next_season_start
    @stat.date_for(:first_frost_median, year + 1)
  end

  def next_season_earliest
    @stat.date_for(:first_frost_p10, year + 1)
  end

  def days_until_usual_start
    (usual.first - @today).to_i
  end

  # Whether the usual first frost is near enough to say it is coming, rather than a long way off.
  def starts_soon?
    days_until_usual_start <= SOON_DAYS
  end

  def days_until_usual_end
    (usual.last - @today).to_i
  end

  def days_until_latest
    (possible.last - @today).to_i
  end

  def days_since_latest
    (@today - possible.last).to_i
  end

  # Positive when the planting went in before the usual last frost danger, negative when after.
  def planted_days_before_usual_end
    (usual.last - @planted_on).to_i
  end

  # The days the planting lived inside the possible frost danger, from the earliest it has come to the latest, in any
  # season its life touched.
  def days_in_danger
    life = start_on..lived_until
    [year - 1, year, year + 1].sum { |season| overlap_days(life, season_dates(season, :first_frost_p10, :last_frost_p90)) }
  end

  def days_to_next_season
    (next_season_start - lived_until).to_i
  end

  # The coldest night the planting had while frost danger was possible, in degrees, or nil with no readings.
  def coldest_night_c
    nights.min
  end

  # How far the coldest night stayed above the frost danger temperature. Zero or less when it reached it.
  def margin_c
    (coldest_night_c - THRESHOLD_C).round(1) if coldest_night_c
  end

  def frost_nights
    nights.count { |temp| temp <= THRESHOLD_C }
  end

  # The dates the timeline covers: whole months, from the earliest possible frost (or the planting, if earlier) to a
  # month past the start of the next season (or the end of the planting, if later).
  def axis
    first = [possible.first, (sown_on if show_safe_days?), start_on].compact.min
    @axis ||= first.beginning_of_month..[next_season_start.next_month.end_of_month, lived_until.end_of_month].max
  end

  # The frost danger on the timeline, for the year the planting went in and the next, cut to the axis.
  def danger_bands
    [year, year + 1].flat_map { |y| bands_for(y) }.filter_map { |band| clip(band) }
  end

  # The planting on the timeline: its days somewhere safe from frost, if it began in one, then the planting outdoors.
  def planting_bands
    bands = [safe_band, *stay_bands]
    bands.compact.filter_map { |band| clip(band) }
  end

  # How far along the axis a date is, from 0 to 1.
  def position(date)
    ((date - axis.first).to_f / axis_days).clamp(0.0, 1.0)
  end

  # How much of the axis a band covers, from 0 to 1.
  def width(band)
    position(band.to + 1) - position(band.from)
  end

  private

  # Whether the timeline draws the days somewhere safe from frost: a planting that has lived longer than a frost year is
  # shown for its last year, and those days are further back than that.
  def show_safe_days?
    from_frost_safe? && !long_lived?
  end

  # The days somewhere safe from frost, before the planting went outdoors.
  def safe_band
    Band.new(:frost_safe, sown_on, planted_on - 1) if show_safe_days?
  end

  # The planting outdoors: one bar once it has finished, else what has happened so far and what is still to come.
  def stay_bands
    if end_unknown?
      [Band.new(:planted, planted_on, planted_on)]
    elsif @finished
      [Band.new(:finished, start_on, ends_on)]
    else
      [Band.new(:so_far, start_on, @today), (Band.new(:still_to_come, @today + 1, ends_on) if ends_on > @today)]
    end
  end

  # The last day the planting has lived through: its end once it has finished, and while it is still growing, the later of
  # its expected end and today, as it carries on past an expected end that has gone by.
  def lived_until
    finished? ? ends_on : [ends_on, today].max
  end

  # The last day the planting has actually lived: the day it finished, or today.
  def age_end
    finished? ? ends_on : today
  end

  # Where the planting's account of frost starts: the day it went in, or for a long-lived planting a year before it ends.
  def start_on
    long_lived? ? age_end - YEAR_DAYS : @planted_on
  end

  # How many days two date ranges share, both ends counted.
  def overlap_days(one, other)
    [([one.last, other.last].min - [one.first, other.first].max).to_i + 1, 0].max
  end

  def year
    @year ||= @stat.frost_year_of(long_lived? ? age_end : @planted_on)
  end

  def season_dates(season_year, first, last)
    @stat.date_for(first, season_year)..@stat.date_for(last, season_year)
  end

  def bands_for(season_year)
    earliest, first, last, latest = %i(first_frost_p10 first_frost_median last_frost_median last_frost_p90).map do |field|
      @stat.date_for(field, season_year)
    end
    [Band.new(:possible, earliest, first - 1), Band.new(:usual, first, last), Band.new(:possible, last + 1, latest)]
  end

  def clip(band)
    from = [band.from, axis.first].max
    to = [band.to, axis.last].min
    Band.new(band.kind, from, to, band.to) if from <= to
  end

  def axis_days
    axis.last - axis.first + 1
  end

  # The minimum temperatures of the planting's nights while frost danger was possible.
  def nights
    @nights ||= @readings.filter_map do |reading|
      next unless reading.temp_min_c && reading.date.between?(start_on,
                                                              lived_until) && reading.date.between?(possible.first, possible.last)

      reading.temp_min_c
    end
  end
end
