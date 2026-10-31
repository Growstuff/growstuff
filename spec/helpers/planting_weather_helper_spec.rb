# frozen_string_literal: true

require 'rails_helper'

describe PlantingWeatherHelper do
  describe '#weather_figures' do
    it 'gives every figure we have' do
      summary = { rain: '7 mm', hottest: '16.5°C', coldest: '6.5°C' }
      expect(helper.weather_figures(summary)).to eq '7 mm of rain, highs up to 16.5°C, and lows down to 6.5°C'
    end

    it 'leaves out the ones we lack' do
      expect(helper.weather_figures({ hottest: '16.5°C' })).to eq 'highs up to 16.5°C'
    end

    it 'is nil when there are none' do
      expect(helper.weather_figures({ days: 3 })).to be_nil
    end
  end
end
