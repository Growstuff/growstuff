# frozen_string_literal: true

require 'rails_helper'

describe OpenMeteoClient, type: :service do
  subject(:client) { described_class.new(connection:) }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) { Faraday.new(url: 'https://api.test') { |f| f.adapter :test, stubs } }
  # Day one is snow: 5mm of water as precipitation, none of it rain.
  let(:body) do
    { daily: { time: %w(2026-10-01 2026-10-02), precipitation_sum: [5.0, nil], rain_sum: [0.0, nil], temperature_2m_max: [14.2, 14.5] } }
  end
  let(:asked) { [] }
  let(:days) { client.daily(latitude: -41.3, longitude: 174.75, from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 2)) }

  around { |example| VCR.turned_off(&example) }

  context 'when the API answers' do
    before do
      stubs.get('/v1/archive') do |env|
        asked << env.params['daily']
        [200, {}, body.to_json]
      end
    end

    it 'counts only rain as rainfall, not snow\'s water' do
      expect(days[Date.new(2026, 10, 1)][:rainfall_mm]).to eq 0.0
    end

    it 'asks for rain' do
      days
      expect(asked.first.split(',')).to include 'rain_sum'
    end

    it 'does not ask for total precipitation' do
      days
      expect(asked.first.split(',')).not_to include 'precipitation_sum'
    end

    it 'maps values to columns by date' do
      expect(days[Date.new(2026, 10, 1)]).to eq(rainfall_mm: 0.0, temp_max_c: 14.2)
    end

    it 'leaves out figures the API lacks' do
      expect(days[Date.new(2026, 10, 2)]).to eq(temp_max_c: 14.5)
    end
  end

  context 'when the API errors' do
    before { stubs.get('/v1/archive') { [429, {}, '{}'] } }

    it 'raises Error' do
      expect { days }.to raise_error(described_class::Error, /429/)
    end
  end
end
