# frozen_string_literal: true

require 'rails_helper'

describe PlantingWeatherHelper do
  include ActiveSupport::Testing::TimeHelpers

  describe 'frost danger' do
    # The default frost_stat is in the south, so a frost year is a calendar year: the first frost danger is around
    # 31 May, as early as 11 May, and the last is around 8 September, as late as 28 September.
    let(:stat) { build(:frost_stat) }

    describe '#frost_danger_figures' do
      subject(:figures) { helper.frost_danger_figures(stat, Date.new(2026, 6, 15)) }

      it 'gives the usual first frost danger and the earliest' do
        expect(figures[:first]).to eq 'about 31 May, as early as 11 May in some years'
      end

      it 'gives the usual last frost danger and the latest' do
        expect(figures[:last]).to eq 'about 8 September, as late as 28 September in some years'
      end

      it 'gives the frost-free days' do
        expect(figures[:free_days]).to eq '280 days'
      end

      it 'leaves out the frost-free days when there are none' do
        stat.frost_free_days_median = nil
        expect(figures).not_to have_key :free_days
      end

      it 'has nothing for a cell with little frost' do
        stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil)
        expect(figures).to eq({})
      end
    end

    describe 'on the charts' do
      # Day 0 is 1 June 2026, so the usual frost danger, 31 May to 8 September, starts a day before the axis.
      let(:from) { Date.new(2026, 6, 1) }
      let(:readings) { [build(:weather_reading, date: from, rainfall_mm: 4.0, temp_max_c: 12.0, temp_min_c: -1.0)] }
      let(:warm) { [build(:weather_reading, date: from, rainfall_mm: 4.0, temp_max_c: 22.0, temp_min_c: 9.0)] }
      let(:rain) { Capybara.string(helper.weather_rain_chart(readings, from:, days: 200, frost: stat)) }
      let(:temperature) { Capybara.string(helper.weather_temperature_chart(readings, from:, days: 200, frost: stat)) }

      it 'draws the usual frost danger' do
        expect(rain).to have_css 'rect.weather-frost', count: 1
      end

      it 'draws the possible frost danger paler, behind it' do
        expect(rain).to have_css 'rect.weather-frost-wide', count: 1
      end

      it 'clips the usual band to the start of the axis' do
        expect(rain.find('rect.weather-frost')[:x]).to eq '0.0'
      end

      it 'draws the bands on the temperature chart too' do
        expect(temperature).to have_css 'rect.weather-frost'
      end

      it 'draws a line at the frost danger temperature when the range reaches it' do
        expect(temperature).to have_css 'line.weather-frost-line'
      end

      it 'leaves out the line when the range is all warmer' do
        chart = Capybara.string(helper.weather_temperature_chart(warm, from:, days: 200, frost: stat))
        expect(chart).to have_no_css 'line.weather-frost-line'
      end

      it 'draws nothing without frost dates' do
        chart = Capybara.string(helper.weather_rain_chart(readings, from:, days: 200, frost: nil))
        expect(chart).to have_no_css 'rect.weather-frost'
      end

      it 'draws nothing for a cell with little frost' do
        stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil)
        expect(rain).to have_no_css 'rect.weather-frost'
      end

      it 'draws nothing when the axis is all outside frost danger' do
        chart = Capybara.string(helper.weather_rain_chart(readings, from: Date.new(2026, 11, 1), days: 30, frost: stat))
        expect(chart).to have_no_css 'rect.weather-frost'
      end
    end

    describe '#frost_danger_timing' do
      it 'says when it was planted before the season' do
        expect(helper.frost_danger_timing(stat,
                                          Date.new(2026, 3, 1))).to eq 'This was planted before frost danger usually starts, around 11 May.'
      end

      it 'says when it was planted before the usual last frost danger' do
        expect(helper.frost_danger_timing(stat,
                                          Date.new(2026, 6,
                                                   15))).to eq 'This was planted before the usual last frost danger, around 8 September.'
      end

      it 'says when it was planted before the safe date' do
        timing = helper.frost_danger_timing(stat, Date.new(2026, 9, 15))
        expect(timing).to eq 'This was planted around the usual end of frost danger, but frost danger can last until 28 September.'
      end

      it 'says when it was planted after it' do
        expect(helper.frost_danger_timing(stat, Date.new(2026, 10, 15))).to eq 'This was planted after the usual end of frost danger.'
      end

      it 'counts a Northern Hemisphere autumn planting in the next frost year' do
        stat.latitude = 51.5
        expect(helper.frost_danger_timing(stat, Date.new(2026, 12, 15))).to include 'before the usual last frost danger'
      end

      it 'is nil for a cell with little frost' do
        stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil)
        expect(helper.frost_danger_timing(stat, Date.new(2026, 6, 15))).to be_nil
      end
    end
  end

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
    subject(:chart) { Capybara.string(helper.weather_temperature_chart(readings, from: Date.new(2026, 10, 1), days: 10)) }

    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 1), temp_max_c: 14.4, temp_min_c: -0.7)] }

    it { expect(chart).to have_css '.weather-axis span:first-child', text: '15°' }
    it { expect(chart).to have_css '.weather-axis span:last-child', text: '-1°' }
    it { expect(chart).to have_css '.weather-axis span', text: '7°' }
    it { expect(chart).to have_css 'line.weather-grid', count: 1 }
  end

  describe '#weather_rain_chart axis' do
    subject(:chart) { Capybara.string(helper.weather_rain_chart(readings, from: Date.new(2026, 10, 1), days: 10)) }

    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 1), rainfall_mm: 6.2)] }

    it { expect(chart).to have_css '.weather-axis span:first-child', text: '7 mm' }
    it { expect(chart).to have_css '.weather-axis span:last-child', text: '0 mm' }
  end
end
