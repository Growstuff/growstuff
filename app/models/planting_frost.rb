# frozen_string_literal: true

# How a planting sits against the frost danger of its place: the usual and the possible frost danger dates around it,
# what the planting went through, and a verdict for the day. It holds the working out for the frost section of the
# planting page, and no text, so the page only has to draw it.
#
# The usual dates are the medians of past years and the possible ones are the earliest and latest it has come: see
# FrostStat. Approximate, regional and experimental.
class PlantingFrost
  # A stretch of the timeline. kind is :usual or :possible for frost danger, and :so_far, :still_to_come or :finished
  # for the planting.
  Band = Struct.new(:kind, :from, :to)

  THRESHOLD_C = FrostCalculator::FROST_DANGER_C
  SOON_DAYS = 60

  attr_reader :planted_on, :ends_on, :today

  def finished?
    @finished
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

    new(stat:, planted_on: planting.planted_at, ends_on: planting.finished_at || planting.weather_due_on,
        finished: planting.finished?, readings:, today:)
  end

  def initialize(stat:, planted_on:, ends_on:, finished:, readings:, today:) # rubocop:disable Metrics/ParameterLists
    @stat = stat
    @planted_on = planted_on
    @finished = finished
    @readings = readings
    @today = today
    @ends_on = ends_on || today
  end

  # What to tell the member today. A planting that has finished is judged on what it went through, one still growing
  # on where today falls in the frost danger season of the year it went in.
  def verdict
    return :rare unless @stat.dated?
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

  # Days from planting to the latest it has come, or to the end of the planting if that is sooner. None if it went in
  # after the latest.
  def days_in_danger
    [([possible.last, lived_until].min - @planted_on).to_i, 0].max
  end

  def days_to_next_season
    (next_season_start - ends_on).to_i
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
    @axis ||= [possible.first,
               @planted_on].min.beginning_of_month..[next_season_start.next_month.end_of_month, lived_until.end_of_month].max
  end

  # The frost danger on the timeline, for the year the planting went in and the next, cut to the axis.
  def danger_bands
    [year, year + 1].flat_map { |y| bands_for(y) }.filter_map { |band| clip(band) }
  end

  # The planting on the timeline: one bar once it has finished, else what has happened so far and what is still to come.
  def planting_bands
    bands = if @finished
              [Band.new(:finished, @planted_on, ends_on)]
            else
              [Band.new(:so_far, @planted_on, @today), (Band.new(:still_to_come, @today + 1, ends_on) if ends_on > @today)]
            end
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

  # The last day the planting has lived through: its end once it has finished, and while it is still growing, the later of
  # its expected end and today, as it carries on past an expected end that has gone by.
  def lived_until
    finished? ? ends_on : [ends_on, today].max
  end

  def year
    @year ||= @stat.frost_year_of(@planted_on)
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
    Band.new(band.kind, from, to) if from <= to
  end

  def axis_days
    axis.last - axis.first + 1
  end

  # The minimum temperatures of the planting's nights while frost danger was possible.
  def nights
    @nights ||= @readings.filter_map do |reading|
      next unless reading.temp_min_c && reading.date.between?(@planted_on,
                                                              lived_until) && reading.date.between?(possible.first, possible.last)

      reading.temp_min_c
    end
  end
end
