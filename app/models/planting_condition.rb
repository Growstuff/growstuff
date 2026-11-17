# frozen_string_literal: true

# A day a planting went through something worth noting on its timeline, worked out from the weather and kept here so the
# page doesn't redo it: a night that reached the frost danger temperature (see PlantingFrost), a day colder than its crop is
# killed at or hotter than its crop's upper limit (see EcocropData), or a day of damaging wind. Refreshed by the daily
# weather update.
class PlantingCondition < ApplicationRecord
  KINDS = %w(frost killing_cold killing_heat damaging_wind).freeze
  # Gusts at or above this, in kilometres an hour, are damaging whatever the crop.
  DAMAGING_GUST_KMH = 90

  # A day of a kind, with the temperature it had and the limit it crossed.
  # Damaging wind days also have where the wind blew from and the day's temperatures.
  WIND_COLUMNS = %i(wind_gust_max_kmh wind_direction_degrees).freeze

  Day = Struct.new(:kind, :occurred_on, :value, :threshold, :direction_degrees, :temp_min_c, :temp_max_c)

  belongs_to :planting

  enum :kind, KINDS.index_with(&:itself)

  validates :occurred_on, presence: true
  validates :occurred_on, uniqueness: { scope: %i(planting_id kind) }

  scope :oldest_first, -> { order(:occurred_on) }

  # Brings the planting's days up to date with its weather, adding the new and dropping those that no longer count, such as
  # after it was replanted. A planting somewhere safe from frost, like a greenhouse, has none.
  def self.refresh(planting, today: Time.zone.today)
    readings = planting.weather_readings.select(*WeatherReading::CHARTED, *WIND_COLUMNS).to_a
    days = frost_days(planting, readings, today) + extreme_days(planting, readings) + wind_days(planting, readings)
    transaction do
      KINDS.each do |kind|
        planting.conditions.where(kind:).where.not(occurred_on: days.select { |day| day.kind == kind }.map(&:occurred_on)).delete_all
      end
      upsert_days(planting, days)
    end
  end

  def self.frost_days(planting, readings, today)
    frost = PlantingFrost.for(planting, readings:, today:)
    return [] unless frost

    frost.frost_night_readings.map { |night| Day.new('frost', night.date, night.temp_min_c, FrostCalculator::FROST_DANGER_C) }
  end

  # The days colder than the crop is killed at or hotter than it takes, by its EcoCrop figures. It has none without them.
  def self.extreme_days(planting, readings)
    data = planting.crop.ecocrop_data
    return [] if data.nil? || planting.garden.frost_safe?

    cold = data.ktmp && readings.select { |day| day.temp_min_c && day.temp_min_c <= data.ktmp }
      .map { |day| Day.new('killing_cold', day.date, day.temp_min_c, data.ktmp) }
    heat = data.tmax && readings.select { |day| day.temp_max_c && day.temp_max_c > data.tmax }
      .map { |day| Day.new('killing_heat', day.date, day.temp_max_c, data.tmax) }
    [*cold, *heat]
  end

  # The days with gusts at or above DAMAGING_GUST_KMH. Somewhere safe from frost, like a greenhouse, is out of the wind too.
  def self.wind_days(planting, readings)
    return [] if planting.garden.frost_safe?

    readings.select { |day| day.wind_gust_max_kmh && day.wind_gust_max_kmh >= DAMAGING_GUST_KMH }.map do |day|
      Day.new('damaging_wind', day.date, day.wind_gust_max_kmh, DAMAGING_GUST_KMH, day.wind_direction_degrees, day.temp_min_c, day.temp_max_c)
    end
  end

  def self.upsert_days(planting, days)
    return if days.empty?

    now = Time.current
    rows = days.map do |day|
      { planting_id: planting.id, kind: day.kind, occurred_on: day.occurred_on, value: day.value, threshold: day.threshold,
        direction_degrees: day.direction_degrees, temp_min_c: day.temp_min_c, temp_max_c: day.temp_max_c,
        created_at: now, updated_at: now }
    end
    upsert_all(rows, unique_by: %i(planting_id kind occurred_on), update_only: %i(value threshold direction_degrees temp_min_c temp_max_c)) # rubocop:disable Rails/SkipsModelValidations
  end
  private_class_method :frost_days, :extreme_days, :wind_days, :upsert_days
end
