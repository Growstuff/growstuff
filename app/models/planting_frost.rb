# frozen_string_literal: true

# How a planting sits against the frost danger of its place: the FrostSeason of the year it went in, and what the
# planting went through. Holds the working out for the frost section of the planting page, and no text.
class PlantingFrost < FrostSeason
  YEAR_DAYS = 365

  attr_reader :planted_on, :ends_on

  # readings: the planting's weather, as WeatherReading rows with temp_min_c.
  def self.for(planting, readings:, today: Time.zone.today)
    stat = planting.frost_danger
    return if stat.nil? || stat.unknown?

    new(stat:, planted_on: planting.planted_at, ends_on: planting.finished_at || planting.weather_due_on,
        finished: planting.finished?, readings:, today:)
  end

  def initialize(stat:, planted_on:, ends_on:, finished:, readings:, today:) # rubocop:disable Metrics/ParameterLists
    super(stat:, today:)
    @planted_on = planted_on
    @finished = finished
    @readings = readings
    @expected_end = !ends_on.nil?
    @ends_on = ends_on || today
  end

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
    !finished? && super
  end

  # A planting that has finished is judged on what it went through, one still growing on where today falls in the
  # frost danger season of the year it went in.
  def verdict
    return super unless finished? && @stat.dated?

    frost_nights.zero? ? :finished_clear : :finished_hit
  end

  # Positive when the planting went in before the usual last frost danger, negative when after.
  def planted_days_before_usual_end
    (usual.last - @planted_on).to_i
  end

  # Days from planting to the latest it has come, or to the end of the planting if that is sooner. None if it went in
  # after the latest.
  def days_in_danger
    [([possible.last, lived_until].min - start_on).to_i, 0].max
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

  # The planting on the timeline: one bar once it has finished, else what has happened so far and what is still to come.
  def planting_bands
    bands = if finished?
              [Band.new(:finished, start_on, ends_on)]
            else
              [Band.new(:so_far, start_on, today), (Band.new(:still_to_come, today + 1, ends_on) if ends_on > today)]
            end
    bands.compact.filter_map { |band| clip(band) }
  end

  private

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

  def season_day
    long_lived? ? age_end : @planted_on
  end

  # The timeline also covers the planting, from its start to its end.
  def axis_first
    [possible.first, start_on].min
  end

  def axis_last
    [next_season_start.next_month, lived_until].max
  end

  # The minimum temperatures of the planting's nights while frost danger was possible.
  def nights
    @nights ||= @readings.filter_map do |reading|
      next unless reading.temp_min_c && reading.date.between?(start_on, lived_until) && reading.date.between?(possible.first, possible.last)

      reading.temp_min_c
    end
  end
end
