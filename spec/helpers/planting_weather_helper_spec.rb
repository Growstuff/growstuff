# frozen_string_literal: true

require 'rails_helper'

describe PlantingWeatherHelper do
  include ActiveSupport::Testing::TimeHelpers

  describe 'the frost line on the temperature chart' do
    let(:from) { Date.new(2026, 6, 1) }
    let(:stat) { build(:frost_stat) }
    let(:readings) { [build(:weather_reading, date: from, rainfall_mm: 4.0, temp_max_c: 22.0, temp_min_c: 9.0)] }
    let(:chart) { Capybara.string(helper.weather_temperature_chart(readings, from:, days: 200, frost: stat)) }

    it 'is drawn when there are frost dates' do
      expect(chart).to have_css 'line.weather-frost-line'
    end

    it 'is labelled' do
      expect(chart).to have_css '.weather-frost-label'
    end

    it 'lowers the axis to zero so the line shows' do
      expect(chart.all('.weather-axis span').last.text).to eq '0°'
    end

    it 'is left out for a cell with little frost' do
      stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil)
      expect(chart).to have_no_css 'line.weather-frost-line'
    end

    it 'is left out without frost dates' do
      without = Capybara.string(helper.weather_temperature_chart(readings, from:, days: 200))
      expect(without).to have_no_css 'line.weather-frost-line'
    end

    it 'leaves the axis alone without frost dates' do
      without = Capybara.string(helper.weather_temperature_chart(readings, from:, days: 200))
      expect(without.all('.weather-axis span').last.text).to eq '9°'
    end
  end

  describe 'the optimal and absolute temperature bands' do
    let(:readings) { [build(:weather_reading, date: Date.new(2026, 10, 1), temp_max_c: 22, temp_min_c: 9)] }
    let(:chart) { Capybara.string(helper.weather_temperature_chart(readings, from: Date.new(2026, 10, 1), days: 10, ranges:)) }
    let(:ranges) { { optimal: [15, 25], absolute: [5, 35] } }

    it 'draws a band for each range' do
      expect(chart).to have_css 'rect.weather-band', count: 2
    end

    it 'places the best range within the axis, 15 to 25 on a 5 to 35 chart' do
      band = chart.find('rect.weather-band--optimal')
      expect([band[:y].to_f, band[:height].to_f]).to eq [40.0, 40.0]
    end

    it 'draws the survivable range over the whole chart' do
      band = chart.find('rect.weather-band--absolute')
      expect([band[:y].to_f, band[:height].to_f]).to eq [0.0, 120.0]
    end

    it 'labels the best range' do
      expect(chart).to have_css '.weather-band-label--optimal', text: 'Grows best 15–25°'
    end

    it 'labels the survivable range' do
      expect(chart).to have_css '.weather-band-label--absolute', text: 'Survives 5–35°'
    end

    it 'stretches the axis to show a range beyond the readings' do
      axis = chart.all('.weather-axis span').map(&:text)
      expect(axis.first).to eq '35°'
    end

    it 'draws a range open at one end to the chart edge' do
      open_ended = Capybara.string(helper.weather_temperature_chart(readings, from: Date.new(2026, 10, 1), days: 10,
                                                                              ranges: { absolute: [5, nil] }))
      expect(open_ended.find('rect.weather-band--absolute')[:y]).to eq '0'
    end

    it 'draws no bands without ranges' do
      plain = Capybara.string(helper.weather_temperature_chart(readings, from: Date.new(2026, 10, 1), days: 10))
      expect(plain).to have_no_css 'rect.weather-band'
    end
  end

  describe '#weather_range_badge' do
    subject(:badge) { Capybara.string(helper.weather_range_badge(readings, ranges, crop:).to_s) }

    let(:crop) { build(:crop, name: 'tomato') }

    let(:ranges) { { optimal: [15, 25], absolute: [5, 35] } }

    def reading(high, low, date: Date.new(2026, 10, 1))
      build(:weather_reading, date:, temp_max_c: high, temp_min_c: low)
    end

    context 'when the day averaged inside the best range' do
      let(:readings) { [reading(24, 14)] }

      it('says so') { expect(badge).to have_css '.badge.text-bg-success', text: 'The planting is in the optimal climate for tomato' }
    end

    context 'when the day was a bit cool' do
      let(:readings) { [reading(14, 8)] }

      it('says so') { expect(badge).to have_css '.badge.text-bg-warning', text: 'Climate a bit cool for tomato' }
    end

    context 'when the day was a bit warm' do
      let(:readings) { [reading(32, 22)] }

      it('says so') { expect(badge).to have_css '.badge.text-bg-warning', text: 'Climate a bit warm for tomato' }
    end

    context 'when the day was colder than the crop survives' do
      let(:readings) { [reading(6, 0)] }

      it('says so') { expect(badge).to have_css '.badge.text-bg-danger', text: 'Climate too cold for tomato' }
    end

    context 'when the day was hotter than the crop survives' do
      let(:readings) { [reading(42, 32)] }

      it('says so') { expect(badge).to have_css '.badge.text-bg-danger', text: 'Climate too hot for tomato' }
    end

    context 'with no best range, inside what it survives' do
      let(:ranges) { { absolute: [5, 35] } }
      let(:readings) { [reading(20, 10)] }

      it('says it survives') { expect(badge).to have_css '.badge.text-bg-secondary', text: 'Climate within what tomato survives' }
    end

    context 'with several days' do
      let(:readings) { [reading(24, 14, date: Date.new(2026, 10, 1)), reading(42, 32, date: Date.new(2026, 10, 2))] }

      it('judges the latest') { expect(badge).to have_css '.badge', text: 'Climate too hot for tomato' }
      it('dates it') { expect(badge).to have_css ".badge[title*='#{I18n.l(Date.new(2026, 10, 2), format: :short)}']" }
    end

    context 'without ranges' do
      let(:ranges) { nil }
      let(:readings) { [reading(24, 14)] }

      it('has no badge') { expect(badge).to have_no_css '.badge' }
    end

    context 'without a high and low to judge' do
      let(:readings) { [build(:weather_reading, temp_max_c: nil, temp_min_c: nil)] }

      it('has no badge') { expect(badge).to have_no_css '.badge' }
    end
  end

  describe '#weather_summary days in the best range' do
    let(:readings) do
      [build(:weather_reading, date: Date.new(2026, 10, 1), temp_max_c: 24, temp_min_c: 14),
       build(:weather_reading, date: Date.new(2026, 10, 2), temp_max_c: 32, temp_min_c: 22),
       build(:weather_reading, date: Date.new(2026, 10, 3), temp_max_c: 22, temp_min_c: 12)]
    end

    it 'counts the days whose average was in the range' do
      expect(helper.weather_summary(readings, ranges: { optimal: [15, 25] })[:best_days]).to eq '2 of 3'
    end

    it 'is left out without a best range' do
      expect(helper.weather_summary(readings)).not_to have_key(:best_days)
    end
  end

  describe '#weather_temperature_ranges' do
    let(:crop) { create(:crop, ecocrop_record: create(:ecocrop_data, topmn: 15, topmx: 25, tmin: 5, tmax: nil)) }

    it 'gives the best range' do
      expect(helper.weather_temperature_ranges(crop)[:optimal]).to eq [15, 25]
    end

    it 'gives a survivable range open at the top' do
      expect(helper.weather_temperature_ranges(crop)[:absolute]).to eq [5, nil]
    end

    it 'is nil for a crop without EcoCrop data' do
      expect(helper.weather_temperature_ranges(create(:crop))).to be_nil
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
