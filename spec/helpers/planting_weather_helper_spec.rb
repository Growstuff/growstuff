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
      expect(chart).to have_css '.weather-band-label--absolute', text: 'Grows at 5–35°'
    end

    context 'with a killing temperature' do
      let(:ranges) { { optimal: [15, 25], absolute: [5, 35], kill: 0 } }

      it 'draws a line at it' do
        expect(chart).to have_css 'line.weather-kill-line'
      end

      it 'labels the line' do
        expect(chart).to have_css '.weather-kill-label', text: 'Dies at 0 °C'
      end
    end

    it 'draws no kill line without one' do
      expect(chart).to have_no_css 'line.weather-kill-line'
    end

    it 'stretches the axis to show a range beyond the readings' do
      axis = chart.all('.weather-axis span').map(&:text)
      expect(axis.first).to eq '35°'
    end

    describe 'where the labels go' do
      def top_of(chart, kind)
        chart.find(".weather-band-label--#{kind}")[:style][/top: ([\d.]+)%/, 1].to_f * 120 / 100
      end

      it 'keeps them below the latest-reading label at the top' do
        expect(top_of(chart, :absolute)).to be >= 20
      end

      context 'when both ranges have the same top edge' do
        let(:ranges) { { optimal: [15, 25], absolute: [5, 25] } }

        it 'moves the best range label down off the survivable one' do
          expect(top_of(chart, :optimal) - top_of(chart, :absolute)).to be >= 14.99
        end
      end

      context 'when a range is open at the top' do
        let(:ranges) { { optimal: [15, 25], absolute: [5, nil] } }

        it 'still keeps the labels apart' do
          expect(top_of(chart, :optimal) - top_of(chart, :absolute)).to be >= 14.99
        end
      end
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

  describe '#weather_climate_notes' do
    subject(:notes) { Capybara.string(helper.weather_climate_notes(readings, ranges, crop:, expected:).to_s) }

    let(:ranges) { { optimal: [10, 24], absolute: [4, 30] } }
    let(:crop) { build(:crop, name: 'pea') }
    let(:expected) { [] }
    let(:readings) { days(mild: 20) }

    # Runs of days, from `from`: mild ones have a high of 18, inside the best range; cool ones a high of 9, outside it but not
    # past what the crop survives; hot ones have a high of 35, and cold ones a low of 1 and a high of 9, past what it survives.
    def days(mild: 0, cool: 0, hot: 0, cold: 0, from: Date.new(2026, 5, 1))
      highs_and_lows = Array.new(mild) { [18, 12] } + Array.new(cool) { [9, 5] } + Array.new(hot) { [35, 20] } + Array.new(cold) do
        [9, 1]
      end
      highs_and_lows.each_with_index.map do |(high, low), index|
        build(:weather_reading, date: from + index, temp_max_c: high, temp_min_c: low)
      end
    end

    context 'when the days were nearly all inside the best range' do
      it('is a success') { expect(notes).to have_css '.weather-note--success', text: 'Good conditions for pea so far' }
      it('has a tick') { expect(notes).to have_css '.weather-note .fa-check-circle' }

      it('counts the days in the best range') {
        expect(notes).to have_css '.weather-note', text: '20 of 20 days had a high inside the best range of 10–24°C'
      }

      it('has no problems') { expect(notes).to have_no_css '.weather-note--danger' }
    end

    context 'when many days went past the range the crop grows in, mostly too hot' do
      let(:readings) { days(mild: 85, hot: 13, cold: 2) }

      it('names the heat as the problem') { expect(notes).to have_css '.weather-note--danger', text: 'Too hot for pea so far' }
      it('stays red for heat') { expect(notes).to have_no_css '.weather-note--cold' }
      it('has a warning triangle') { expect(notes).to have_css '.weather-note--danger .fa-exclamation-triangle' }

      it 'says which days went wrong, with the limits' do
        expect(notes).to have_css '.weather-note--danger',
                                  text: 'too hot on 13 days (highs above 30°C) and too cold on 2 days (lows below 4°C)'
      end

      it('still counts the days in the best range') {
        expect(notes).to have_css '.weather-note', text: '85 of 100 days had a high inside the best range'
      }
    end

    context 'when it was too hot on many days and too cold on many others' do
      let(:readings) { days(mild: 70, hot: 15, cold: 15) }

      it('names both') { expect(notes).to have_css '.weather-note--danger', text: 'Too hot and too cold for pea so far' }
    end

    context 'when the lows reached the temperature that kills the crop' do
      let(:ranges) { { optimal: [10, 24], absolute: [4, 30], kill: 2 } }
      let(:readings) { days(mild: 90, cold: 10) }

      it('has a skull') { expect(notes).to have_css '.weather-note--danger .fa-skull' }
      it('is blue, not red, for the cold') { expect(notes).to have_css '.weather-note--cold' }
      it('has a snowflake for the cold') { expect(notes).to have_css '.weather-note--danger .fa-snowflake' }
      it('says how many days') { expect(notes).to have_css '.weather-note', text: 'reached the killing temperature of 2°C on 10 days' }
    end

    context 'when the lows stayed above the killing temperature' do
      let(:ranges) { { optimal: [10, 24], absolute: [4, 30], kill: 0 } }
      let(:readings) { days(mild: 90, cold: 10) }

      it('has no skull') { expect(notes).to have_no_css '.fa-skull' }
    end

    context 'when only a few days went past the survivable limits' do
      let(:readings) { days(mild: 98, hot: 2) }

      it('is mixed, not a warning') { expect(notes).to have_css '.weather-note--caution', text: 'Mixed conditions for pea so far' }
      it('still says what happened') { expect(notes).to have_css '.weather-note--caution', text: 'too hot on 2 days' }
    end

    context 'when it was mostly outside the best range but never past the range the crop grows in' do
      let(:readings) { days(mild: 3, cool: 7) }

      it('is no warning') { expect(notes).to have_css '.weather-note--neutral' }
      it('has no caution or danger') { expect(notes).to have_no_css '.weather-note--caution, .weather-note--danger' }

      it('says the crop grows, though not at the fastest') {
        expect(notes).to have_css '.weather-note', text: 'Growing, though not at the fastest'
      }

      it('counts the days below the best range') { expect(notes).to have_css '.weather-note', text: 'below the best range on 7 days' }
    end

    context 'when the crop has only survivable limits' do
      let(:ranges) { { absolute: [4, 30] } }

      it('says the weather stayed within the range it grows in') {
        expect(notes).to have_css '.weather-note--neutral', text: 'stayed within the range pea grows in'
      }
    end

    context 'with expected weather for the days still to come' do
      let(:expected) { days(mild: 30, from: Date.new(2026, 11, 20)) }

      it('has a note for the past and one for the future') { expect(notes).to have_css '.weather-note', count: 2 }
      it('judges the future') { expect(notes).to have_css '.weather-note--success', text: 'Expected to suit pea' }

      it('says it is going by last year') {
        expect(notes).to have_css '.weather-note', text: "Going by last year's weather, 30 of the 30 days"
      }
    end

    context 'when the expected weather will be too hot' do
      let(:expected) { days(mild: 10, hot: 20, from: Date.new(2026, 11, 20)) }

      it 'warns about the future' do
        expect(notes).to have_css '.weather-note--danger', text: 'Expected to be too hot for pea'
      end

      it('says it could be too hot') { expect(notes).to have_css '.weather-note--danger', text: 'It could be too hot on 20 days' }
    end

    context 'for a planting that has not started, with only expected weather' do
      let(:readings) { [] }
      let(:expected) { days(mild: 30, from: Date.new(2026, 11, 20)) }

      it('has just the future note') { expect(notes).to have_css '.weather-note', count: 1 }
    end

    context 'when the planting was expected to finish partway through the days' do
      subject(:notes) { Capybara.string(helper.weather_climate_notes(readings, ranges, crop:, through: Date.new(2026, 5, 20)).to_s) }

      let(:readings) { days(mild: 20) + days(cold: 30, from: Date.new(2026, 5, 21)) }

      it('judges only the days up to its expected finish') { expect(notes).to have_css '.weather-note--success', text: '20 of 20 days' }
      it('is not marked down for the weather after it') { expect(notes).to have_no_css '.weather-note--danger' }
    end

    context 'without ranges' do
      let(:ranges) { nil }

      it('has no notes') { expect(notes).to have_no_css '.weather-note' }
    end

    context 'without any days with a high and low' do
      let(:readings) { [build(:weather_reading, temp_max_c: nil, temp_min_c: nil)] }

      it('has no notes') { expect(notes).to have_no_css '.weather-note' }
    end
  end

  describe '#weather_summary days in the best range' do
    let(:readings) do
      [build(:weather_reading, date: Date.new(2026, 10, 1), temp_max_c: 24, temp_min_c: 14),
       build(:weather_reading, date: Date.new(2026, 10, 2), temp_max_c: 32, temp_min_c: 22),
       build(:weather_reading, date: Date.new(2026, 10, 3), temp_max_c: 22, temp_min_c: 12)]
    end

    it 'counts the days whose high was in the range' do
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

    it 'gives the killing temperature' do
      crop.ecocrop_data.update!(ktmp: -2)
      expect(helper.weather_temperature_ranges(crop)[:kill]).to eq(-2)
    end

    it 'gives a survivable range open at the top' do
      expect(helper.weather_temperature_ranges(crop)[:absolute]).to eq [5, nil]
    end

    it 'is nil for a crop without EcoCrop data' do
      expect(helper.weather_temperature_ranges(create(:crop))).to be_nil
    end
  end

  describe '#weather_temperature_ranges remembered for a day' do
    let(:crop) { create(:crop, ecocrop_record: create(:ecocrop_data, topmn: 10, topmx: 24, tmin: 4, tmax: 30)) }

    before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

    it 'finds the EcoCrop record once for repeated calls' do
      expect(crop).to receive(:ecocrop_data).once.and_call_original
      2.times { helper.weather_temperature_ranges(crop) }
    end

    it 'finds it again when the crop has changed' do
      helper.weather_temperature_ranges(crop)
      crop.update!(name: 'a new name')
      expect(crop).to receive(:ecocrop_data).once.and_call_original
      helper.weather_temperature_ranges(crop)
    end

    it 'finds it again the next day' do
      helper.weather_temperature_ranges(crop)
      expect(crop).to receive(:ecocrop_data).once.and_call_original
      travel_to(Time.zone.today + 1) { helper.weather_temperature_ranges(crop) }
    end

    it 'remembers a crop with no EcoCrop data too' do
      bare = create(:crop)
      expect(bare).to receive(:ecocrop_data).once.and_call_original
      2.times { helper.weather_temperature_ranges(bare) }
    end
  end

  describe '#weather_place' do
    def place(location) = helper.weather_place(build(:garden, location:))

    it('keeps the first two parts') { expect(place('Bluff, Southland, New Zealand')).to eq 'Bluff, Southland' }
    it('keeps a single part') { expect(place('Hobart')).to eq 'Hobart' }
    it('tidies the spacing') { expect(place(' Hobart ,  Tas ')).to eq 'Hobart, Tas' }
    it('is nil without a location') { expect(place('')).to be_nil }
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
