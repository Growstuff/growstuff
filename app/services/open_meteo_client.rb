# frozen_string_literal: true

# Daily weather from the Open-Meteo historical API (ERA5 reanalysis, CC BY 4.0).
# https://open-meteo.com/en/docs/historical-weather-api
class OpenMeteoClient
  class Error < StandardError; end

  URL = 'https://archive-api.open-meteo.com'
  SOURCE = 'open-meteo'
  USER_AGENT = 'Growstuff (https://github.com/Growstuff/growstuff)'

  # Open-Meteo's name for each daily value, and the WeatherReading column it fills.
  VARIABLES = {
    'rain_sum'                       => :rainfall_mm,
    'temperature_2m_max'             => :temp_max_c,
    'temperature_2m_min'             => :temp_min_c,
    'et0_fao_evapotranspiration'     => :evapotranspiration_mm,
    'wind_speed_10m_max'             => :wind_max_kmh,
    'shortwave_radiation_sum'        => :radiation_mj_m2,
    'temperature_2m_mean'            => :temp_mean_c,
    'apparent_temperature_max'       => :feels_like_max_c,
    'apparent_temperature_min'       => :feels_like_min_c,
    'apparent_temperature_mean'      => :feels_like_mean_c,
    'soil_temperature_0_to_7cm_mean' => :soil_temp_c,
    'soil_moisture_0_to_7cm_mean'    => :soil_moisture_m3_m3,
    'sunshine_duration'              => :sunshine_seconds,
    'daylight_duration'              => :daylight_seconds,
    'cloud_cover_mean'               => :cloud_cover_percent,
    'relative_humidity_2m_mean'      => :humidity_percent,
    'dew_point_2m_mean'              => :dew_point_c,
    'vapour_pressure_deficit_max'    => :vapour_pressure_deficit_kpa,
    'snowfall_sum'                   => :snowfall_cm,
    'precipitation_hours'            => :precipitation_hours,
    'wind_gusts_10m_max'             => :wind_gust_max_kmh,
    'wind_direction_10m_dominant'    => :wind_direction_degrees,
    'surface_pressure_mean'          => :pressure_hpa,
    'weather_code'                   => :weather_code
  }.freeze

  def initialize(connection: nil)
    @connection = connection || Faraday.new(url: URL, headers: { 'User-Agent' => USER_AGENT }) do |f|
      f.options.timeout = 15
    end
  end

  # => { Date => { rainfall_mm: 1.2, temp_max_c: 21.0, ... } }, leaving out any figure the API lacks.
  def daily(latitude:, longitude:, from:, to:)
    response = @connection.get('/v1/archive', latitude:, longitude:, start_date: from.iso8601, end_date: to.iso8601,
                                              daily: VARIABLES.keys.join(','), timezone: 'auto')
    raise Error, "Open-Meteo answered #{response.status}" unless response.success?

    daily = JSON.parse(response.body).fetch('daily', {})
    daily.fetch('time', []).each_with_index.to_h do |day, index|
      [Date.parse(day), VARIABLES.to_h { |name, column| [column, daily.dig(name, index)] }.compact]
    end
  rescue Faraday::Error, JSON::ParserError => e
    raise Error, e.message
  end
end
