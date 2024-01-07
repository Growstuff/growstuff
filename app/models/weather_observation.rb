# frozen_string_literal: true

# A weather observation is intended to be a snapshot aligned to
# https://github.com/schemaorg/schemaorg/issues/362
class WeatherObservation < ApplicationRecord
  belongs_to :owner

  validates :source, presence: true
  validates :observed_at, presence: true

  attr_accessible :source, :observation_at, :solvar_uv_index, :dew_point_temperature_centigrade,
                  :air_temperature_centigrade, :relative_humidity, :wind_speed_kmh, :wind_gust_speed_kmh, :owner_id, :wind_direction, :precipitation_probability, :pressure,
                  :visibility_distance_metres, :weather_type

  # Lowest temp on earth: -89.2°C (-128.6°F)
  # Highest:  56.7°C
  validates :dew_point_temperature_centigrade, numericality: { min: -90, max: 60 }, allow_nil: true
  validates :air_temperature_centigrade, numericality: { min: -90, max: 60 }, allow_nil: true
  validates :relative_humidity, numericality: { min: 0, max: 100 }, allow_nil: true
  validates :wind_speed_kmh, numericality: { min: 0, max: 450 }, allow_nil: true # Highest 408 km/h
  validates :wind_gust_speed_kmh, min: 0, max: 450, allow_nil: true # Highest 408 km/h
end
