# frozen_string_literal: true

# A day the weather in one cell of the weather grid reached something worth noting on a planting's timeline, kept once for
# the place and not for every planting in it: a night that reached the frost danger temperature, a day of damaging wind, heavy
# rain or extreme heat, or the first snowfall of a winter. Worked out from the cell's WeatherReading rows by the daily weather
# update. What a planting's own crop can't take is in PlantingCondition.
class PlaceCondition < ApplicationRecord
  include OnWeatherGrid

  KINDS = %w(frost damaging_wind heavy_rain extreme_heat first_snow).freeze
  FROST_C = FrostCalculator::FROST_DANGER_C
  # Gusts at or above this, in kilometres an hour, are damaging.
  DAMAGING_GUST_KMH = 100
  # A day with this much rain or more is heavy rain, and one with a high over EXTREME_HEAT_C is extreme heat.
  HEAVY_RAIN_MM = 100
  EXTREME_HEAT_C = 40
  COLUMNS = %i(date temp_min_c temp_max_c rainfall_mm snowfall_cm wind_gust_max_kmh wind_direction_degrees).freeze

  # A day of a kind, with its figure and the limit it crossed. Damaging wind also has where it blew from and the temperatures.
  Day = Struct.new(:kind, :occurred_on, :value, :threshold, :direction_degrees, :temp_min_c, :temp_max_c)

  enum :kind, KINDS.index_with(&:itself)

  validates :occurred_on, presence: true
  validates :occurred_on, uniqueness: { scope: %i(latitude longitude kind) }

  scope :oldest_first, -> { order(:occurred_on) }
  scope :between, ->(from, to) { where(occurred_on: from..to) }

  # Brings the cell's days up to date with the weather we hold for it, adding the new and dropping those that no longer count.
  def self.refresh(latitude, longitude)
    readings = WeatherReading.at(latitude, longitude).order(:date).select(*COLUMNS).to_a
    days = readings.flat_map { |reading| days_of(reading) } + first_snow_days(latitude, readings)
    transaction do
      KINDS.each do |kind|
        at(latitude, longitude).where(kind:).where.not(occurred_on: days.select { |day| day.kind == kind }.map(&:occurred_on)).delete_all
      end
      upsert_days(latitude, longitude, days)
    end
  end

  def self.days_of(reading)
    low = reading.temp_min_c
    high = reading.temp_max_c
    gust = reading.wind_gust_max_kmh
    rain = reading.rainfall_mm
    days = []
    days << Day.new('frost', reading.date, low, FROST_C) if low && low <= FROST_C
    if gust && gust >= DAMAGING_GUST_KMH
      days << Day.new('damaging_wind', reading.date, gust, DAMAGING_GUST_KMH, reading.wind_direction_degrees, low, high)
    end
    days << Day.new('heavy_rain', reading.date, rain, HEAVY_RAIN_MM) if rain && rain >= HEAVY_RAIN_MM
    days << Day.new('extreme_heat', reading.date, high, EXTREME_HEAT_C) if high && high > EXTREME_HEAT_C
    days
  end

  # The first snowfall of each winter, where a winter is a frost year (the calendar year in the south, July to June in the
  # north). It is only the first when we hold every day's weather from the start of that winter to the snowfall, so a winter we
  # can't vouch for is left out.
  def self.first_snow_days(latitude, readings)
    held = readings.to_set(&:date)
    readings.select { |reading| reading.snowfall_cm.to_f.positive? }.group_by { |reading| FrostYear.containing(reading.date, latitude:) }
      .filter_map do |year, snowy|
        first = snowy.first
        start = FrostYear.start_of(year, latitude:)
        Day.new('first_snow', first.date, first.snowfall_cm, nil) if (start..first.date).all? { |date| held.include?(date) }
      end
  end

  def self.upsert_days(latitude, longitude, days)
    return if days.empty?

    now = Time.current
    rows = days.map do |day|
      { latitude:, longitude:, kind: day.kind, occurred_on: day.occurred_on, value: day.value, threshold: day.threshold,
        direction_degrees: day.direction_degrees, temp_min_c: day.temp_min_c, temp_max_c: day.temp_max_c, created_at: now, updated_at: now }
    end
    upsert_all(rows, unique_by:   %i(latitude longitude kind occurred_on), # rubocop:disable Rails/SkipsModelValidations
                     update_only: %i(value threshold direction_degrees temp_min_c temp_max_c))
  end
  private_class_method :days_of, :first_snow_days, :upsert_days
end
