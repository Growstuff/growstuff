# A weather observation is intended to be a snapshot aligned to
# https://github.com/schemaorg/schemaorg/issues/362
class WeatherObservation < ApplicationRecord
  belongs_to :garden

  validates :source, presence: true
  validates :observed_at, presence: true

  # Lowest temp on earth: -89.2°C (-128.6°F)
  # Highest:  56.7°C
  validates :dew_point_temperature_centigrade, min: -90, max: 60
  validates :air_temperature_centigrade, min: -90, max: 60
  validates :relative_humidity, min: 0, max: 100
  validates :wind_speed_kmh, min: 0, max: 450 # Highest 408 km/h
  validates :wind_gust_speed_kmh, min: 0, max: 450 # Highest 408 km/h
end
