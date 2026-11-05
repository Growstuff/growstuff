# frozen_string_literal: true

require 'rails_helper'

describe PlantingWeatherHelper do
  include ActiveSupport::Testing::TimeHelpers

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

  describe '#weather_now' do
    let(:today) { Date.new(2026, 10, 15) }
    let(:planting) { build(:planting, planted_at: Date.new(2026, 10, 1), finished_at: nil) }

    before { travel_to(today) }

    it 'is today for a planting in progress' do
      expect(helper.weather_now(planting, 100)).to eq today
    end

    it 'is nil for a finished planting' do
      planting.finished_at = Date.new(2026, 10, 10)
      expect(helper.weather_now(planting, 100)).to be_nil
    end

    it 'is nil once the axis has ended' do
      expect(helper.weather_now(planting, 10)).to be_nil
    end
  end

  describe '#weather_rain_chart' do
    subject(:chart) { Capybara.string(helper.weather_rain_chart(readings, from: Date.new(2026, 10, 1), days: 10, now:)) }

    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 2), rainfall_mm: 3.0)] }

    context 'with a now' do
      let(:now) { Date.new(2026, 10, 3) }

      it { expect(chart).to have_css 'line.weather-now[x1="150.0"]' }
      it { expect(chart).to have_css '.weather-now-label', text: 'Latest, Oct 02: 3.0 mm' }
    end

    context 'without a now' do
      let(:now) { nil }

      it { expect(chart).to have_no_css 'line.weather-now' }
      it { expect(chart).to have_no_css '.weather-now-label' }
    end
  end

  describe '#weather_temperature_chart' do
    subject(:chart) { Capybara.string(helper.weather_temperature_chart(readings, from: Date.new(2026, 10, 1), days: 10, ecocrop:)) }

    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 1), temp_max_c: 14.4, temp_min_c: -0.7)] }
    let(:ecocrop) { nil }

    it { expect(chart).to have_css '.weather-axis span:first-child', text: '15°' }
    it { expect(chart).to have_css '.weather-axis span:last-child', text: '-1°' }
    it { expect(chart).to have_css '.weather-axis span', text: '7°' }
    it { expect(chart).to have_css 'line.weather-grid', count: 1 }
    it { expect(chart).to have_no_css 'rect.weather-temp-suboptimal' }
    it { expect(chart).to have_no_css 'rect.weather-temp-extreme' }

    context 'with ecocrop data' do
      let(:ecocrop) { build(:ecocrop_data, topmn: 5, topmx: 10, tmin: 0, tmax: 12) }

      it 'renders faint orange backgrounds for temperatures outside optimal' do
        expect(chart).to have_css 'rect.weather-temp-suboptimal', count: 2
      end

      it 'renders faint red backgrounds for temperatures outside maximums' do
        expect(chart).to have_css 'rect.weather-temp-extreme', count: 2
      end
    end
  end

  describe '#weather_rain_chart axis' do
    subject(:chart) { Capybara.string(helper.weather_rain_chart(readings, from: Date.new(2026, 10, 1), days: 10)) }

    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 1), rainfall_mm: 6.2)] }

    it { expect(chart).to have_css '.weather-axis span:first-child', text: '7 mm' }
    it { expect(chart).to have_css '.weather-axis span:last-child', text: '0 mm' }
  end
end
