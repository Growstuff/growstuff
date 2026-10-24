# frozen_string_literal: true

require 'rails_helper'

describe WeatherService do
  let(:member) { build(:member, latitude: -37.81, longitude: 144.96, location: 'Melbourne, Australia') }
  let(:today) { Date.current }

  let(:mock_open_meteo_response) do
    {
      'daily' => {
        'time' => (0..15).map { |i| (today + i.days).to_s },
        'weather_code' => [80, 81, 0, 1, 2, 3, 95, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'temperature_2m_max' => [20.0, 18.0, 22.0, 25.0, 24.0, 19.0, 30.0, 22.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0, 14.0],
        'temperature_2m_min' => [10.0, 9.0, 11.0, 14.0, 13.0, 8.0, 18.0, 12.0, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0],
        'precipitation_sum' => [5.0, 12.0, 0.0, 0.0, 0.0, 0.0, 15.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'precipitation_probability_max' => [80, 90, 10, 5, 10, 15, 95, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'wind_speed_10m_max' => [15.0, 25.0, 10.0, 12.0, 11.0, 14.0, 35.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
      }
    }
  end

  describe '.forecast_for' do
    it 'returns nil if member is blank or missing latitude/longitude' do
      expect(WeatherService.forecast_for(nil)).to be_nil
      no_location_member = build(:member, latitude: nil, longitude: nil)
      expect(WeatherService.forecast_for(no_location_member)).to be_nil
    end

    it 'fetches and returns a Forecast object when coordinates are present' do
      allow(Rails.cache).to receive(:fetch).and_return(mock_open_meteo_response)
      forecast = WeatherService.forecast_for(member)
      expect(forecast).to be_a(WeatherService::Forecast)
    end
  end

  describe WeatherService::Forecast do
    subject(:forecast) { WeatherService::Forecast.new(mock_open_meteo_response, unit) }

    context 'with celsius unit' do
      let(:unit) { 'celsius' }

      it 'summarizes forecast for today in Celsius' do
        summary = forecast.summary_for(today)
        expect(summary[:high_temp]).to eq '20°C'
        expect(summary[:low_temp]).to eq '10°C'
        expect(summary[:precip_sum]).to eq 5.0
        expect(summary[:precip_text]).to eq '5.0mm rain'
        expect(summary[:condition]).to eq 'Slight rain showers'
        expect(summary[:brief_description]).to include '20°C / 10°C'
        expect(summary[:brief_description]).to include '5.0mm rain'
        expect(summary[:attribution_url]).to eq 'https://open-meteo.com/en/licence'
      end

      it 'summarizes forecast for date range' do
        summary = forecast.summary_for(today, today + 1.day)
        expect(summary[:high_temp]).to eq '20°C'
        expect(summary[:low_temp]).to eq '9°C'
        expect(summary[:precip_sum]).to eq 17.0
        expect(summary[:daily_details].size).to eq 2
      end
    end

    context 'with fahrenheit unit' do
      let(:unit) { 'fahrenheit' }

      it 'converts temperatures to Fahrenheit' do
        summary = forecast.summary_for(today)
        # 20 C = 68 F, 10 C = 50 F
        expect(summary[:high_temp]).to eq '68°F'
        expect(summary[:low_temp]).to eq '50°F'
        expect(summary[:brief_description]).to include '68°F / 50°F'
      end
    end
  end
end
