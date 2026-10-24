# frozen_string_literal: true

require 'net/http'
require 'json'

class WeatherService
  ATTRIBUTION_URL = 'https://open-meteo.com/en/licence'
  ATTRIBUTION_NAME = 'Open-Meteo'
  ATTRIBUTION_TEXT = 'Weather forecast by Open-Meteo.com'

  WMO_CODES = {
    0 => 'Clear sky',
    1 => 'Mainly clear',
    2 => 'Partly cloudy',
    3 => 'Overcast',
    45 => 'Fog',
    48 => 'Depositing rime fog',
    51 => 'Light drizzle',
    53 => 'Moderate drizzle',
    55 => 'Dense drizzle',
    56 => 'Light freezing drizzle',
    57 => 'Dense freezing drizzle',
    61 => 'Slight rain',
    63 => 'Moderate rain',
    65 => 'Heavy rain',
    66 => 'Light freezing rain',
    67 => 'Heavy freezing rain',
    71 => 'Slight snow',
    73 => 'Moderate snow',
    75 => 'Heavy snow',
    77 => 'Snow grains',
    80 => 'Slight rain showers',
    81 => 'Moderate rain showers',
    82 => 'Violent rain showers',
    85 => 'Slight snow showers',
    86 => 'Heavy snow showers',
    95 => 'Thunderstorm',
    96 => 'Thunderstorm with slight hail',
    99 => 'Thunderstorm with heavy hail'
  }.freeze

  attr_reader :member, :latitude, :longitude, :unit

  def self.forecast_for(member)
    return nil if member.blank? || member.latitude.blank? || member.longitude.blank?

    new(member).forecast
  end

  def initialize(member)
    @member = member
    @latitude = member.latitude
    @longitude = member.longitude
    @unit = member.temperature_unit
  end

  def forecast
    raw_data = fetch_raw_data
    return nil if raw_data.blank? || raw_data['daily'].blank?

    Forecast.new(raw_data, unit)
  end

  private

  def fetch_raw_data
    lat = latitude.round(2)
    lng = longitude.round(2)
    cache_key = "open_meteo_forecast_#{lat}_#{lng}_#{Time.zone.today}"

    Rails.cache.fetch(cache_key, expires_in: 2.hours) do
      query = URI.encode_www_form(
        latitude: lat,
        longitude: lng,
        daily: 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max',
        forecast_days: 16,
        timezone: 'auto'
      )
      url = URI("https://api.open-meteo.com/v1/forecast?#{query}")
      response = Net::HTTP.get_response(url)
      response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
    end
  rescue StandardError => e
    Rails.logger.error("WeatherService error: #{e.message}")
    nil
  end

  class Forecast
    attr_reader :raw_data, :unit

    def initialize(raw_data, unit)
      @raw_data = raw_data
      @unit = unit
    end

    def daily_data
      @daily_data ||= begin
        daily = raw_data['daily'] || {}
        times = daily['time'] || []
        codes = daily['weather_code'] || []
        t_max = daily['temperature_2m_max'] || []
        t_min = daily['temperature_2m_min'] || []
        p_sum = daily['precipitation_sum'] || []
        p_prob = daily['precipitation_probability_max'] || []
        w_speed = daily['wind_speed_10m_max'] || []

        times.each_with_index.map do |time_str, i|
          {
            date: Date.parse(time_str),
            weather_code: codes[i],
            temp_max_c: t_max[i],
            temp_min_c: t_min[i],
            precip_sum: p_sum[i],
            precip_prob_max: p_prob[i],
            wind_speed_max: w_speed[i]
          }
        end
      end
    end

    def summary_for(from_date, to_date = from_date)
      matching = daily_data.select { |d| d[:date] >= from_date && d[:date] <= to_date }
      return nil if matching.empty?

      max_c = matching.filter_map { |d| d[:temp_max_c] }.max
      min_c = matching.filter_map { |d| d[:temp_min_c] }.min
      precip_sum = matching.filter_map { |d| d[:precip_sum] }.sum.round(1)
      codes = matching.filter_map { |d| d[:weather_code] }

      primary_code = select_primary_weather_code(codes)
      condition_text = WMO_CODES[primary_code] || 'Weather'

      high_temp_str = format_temp(max_c)
      low_temp_str = format_temp(min_c)

      precip_text = precip_sum.positive? ? "#{precip_sum}mm rain" : 'No rain'

      parts = []
      parts << "#{high_temp_str} / #{low_temp_str}" if high_temp_str && low_temp_str
      parts << precip_text if precip_sum.positive?
      parts << condition_text

      brief_description = parts.join(', ')

      daily_details = matching.map do |d|
        c_code = d[:weather_code]
        {
          date: d[:date],
          high_temp: format_temp(d[:temp_max_c]),
          low_temp: format_temp(d[:temp_min_c]),
          condition: WMO_CODES[c_code] || 'Weather',
          precip_sum: d[:precip_sum]&.round(1),
          precip_prob: d[:precip_prob_max],
          wind_speed: d[:wind_speed_max]
        }
      end

      {
        high_temp: high_temp_str,
        low_temp: low_temp_str,
        precip_sum: precip_sum,
        precip_text: precip_text,
        condition: condition_text,
        brief_description: brief_description,
        daily_details: daily_details,
        attribution_url: ATTRIBUTION_URL,
        attribution_text: ATTRIBUTION_TEXT
      }
    end

    private

    def format_temp(celsius)
      return nil if celsius.nil?

      if unit == 'fahrenheit'
        f = (celsius * 9.0 / 5.0) + 32
        "#{f.round}°F"
      else
        "#{celsius.round}°C"
      end
    end

    def select_primary_weather_code(codes)
      return 0 if codes.empty?

      severity_order = [95, 96, 99, 75, 86, 73, 85, 71, 77, 65, 67, 82, 63, 81, 61, 80, 55, 57, 53, 56, 51, 48, 45, 3, 2, 1, 0]
      codes.min_by { |code| severity_order.index(code) || 999 }
    end
  end
end
