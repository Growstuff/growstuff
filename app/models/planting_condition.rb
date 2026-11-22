# frozen_string_literal: true

# A day a planting went through something its own crop can't take, worked out from the weather and kept here so the page
# doesn't redo it: a day colder than the crop is killed at, or hotter than its upper limit (see EcocropData). What the weather
# did to the place, whatever the crop, is in PlaceCondition. Refreshed by the daily weather update.
class PlantingCondition < ApplicationRecord
  KINDS = %w(killing_cold killing_heat).freeze

  belongs_to :planting

  enum :kind, KINDS.index_with(&:itself)

  validates :occurred_on, presence: true
  validates :occurred_on, uniqueness: { scope: %i(planting_id kind) }

  scope :oldest_first, -> { order(:occurred_on) }

  # Brings the planting's days up to date with its weather, adding the new and dropping those that no longer count, such as
  # after it was replanted. A planting somewhere safe from frost, like a greenhouse, has none, nor has a crop with no EcoCrop
  # killing temperature or upper limit.
  def self.refresh(planting)
    days = days_of(planting)
    transaction do
      KINDS.each do |kind|
        planting.conditions.where(kind:).where.not(occurred_on: days.select { |day| day[:kind] == kind }.pluck(:occurred_on)).delete_all
      end
      upsert_days(planting, days)
    end
  end

  def self.days_of(planting)
    data = planting.crop.ecocrop_data
    return [] if data.nil? || planting.garden.frost_safe?

    readings = planting.weather_readings.select(*WeatherReading::CHARTED).to_a
    cold = data.ktmp && readings.select { |day| day.temp_min_c && day.temp_min_c <= data.ktmp }
      .map { |day| { kind: 'killing_cold', occurred_on: day.date, value: day.temp_min_c, threshold: data.ktmp } }
    heat = data.tmax && readings.select { |day| day.temp_max_c && day.temp_max_c > data.tmax }
      .map { |day| { kind: 'killing_heat', occurred_on: day.date, value: day.temp_max_c, threshold: data.tmax } }
    [*cold, *heat]
  end

  def self.upsert_days(planting, days)
    return if days.empty?

    now = Time.current
    rows = days.map { |day| day.merge(planting_id: planting.id, created_at: now, updated_at: now) }
    upsert_all(rows, unique_by: %i(planting_id kind occurred_on), update_only: %i(value threshold)) # rubocop:disable Rails/SkipsModelValidations
  end
  private_class_method :days_of, :upsert_days
end
