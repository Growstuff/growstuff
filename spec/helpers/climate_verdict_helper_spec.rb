# frozen_string_literal: true

require 'rails_helper'

describe ClimateVerdictHelper do
  let(:today) { Date.new(2026, 3, 20) }
  # Two past years of 100 mm of rain and 17 degrees in the air a month, and this year's January and February.
  let(:past) do
    [2024, 2025].flat_map do |year|
      (1..12).map do |month|
        build(:climate_month, year:, month:, days: Time.days_in_month(month, year), rain_mm: 100.0, temp_mean_c: 17.0, soil_temp_c: 15.0)
      end
    end
  end
  let(:this_year) do
    [[1, 31], [2, 28]].map do |month, days|
      build(:climate_month, year: 2026, month:, days:, rain_mm: rain, temp_mean_c: air, soil_temp_c: 16.0)
    end
  end
  let(:rain) { 100.0 }
  let(:air) { 17.0 }
  let(:recent) { nil }
  let(:climate) { PlaceClimate.new(past + this_year, today:, recent:) }

  describe '#climate_rain_verdict' do
    subject(:verdict) { helper.climate_rain_verdict(climate) }

    it 'says it is close to usual for about the usual rain' do
      expect(verdict[:title]).to eq I18n.t('climate.rain.verdicts.close')
    end

    it 'gives the rain, the usual and the share in the sentence' do
      expect(verdict[:body]).to eq '200 mm has fallen since 1 January. That is 100% of the usual 200 mm by this date.'
    end

    context 'with a dry start to the year' do
      let(:rain) { 40.0 }

      it { expect(verdict[:title]).to eq I18n.t('climate.rain.verdicts.drier') }
    end

    context 'with no weather for this year' do
      let(:this_year) { [] }

      it { is_expected.to be_nil }
    end
  end

  describe '#climate_air_verdict' do
    subject(:verdict) { helper.climate_air_verdict(climate) }

    context 'with a year warmer than usual' do
      let(:air) { 18.5 }

      it 'says so' do
        expect(verdict[:title]).to eq I18n.t('climate.air.verdicts.warmer')
      end

      it 'says how far above usual' do
        expect(verdict[:body]).to include '1.5 °C above the usual 17.0 °C'
      end
    end

    context 'with a year colder than usual' do
      let(:air) { 15.0 }

      it 'says how far below usual' do
        expect(verdict[:body]).to include '2.0 °C below the usual 17.0 °C'
      end
    end

    context 'with a year as warm as usual' do
      it 'says it is close' do
        expect(verdict[:title]).to eq I18n.t('climate.air.verdicts.close')
      end
    end

    context 'without the latest 30 days' do
      it { expect(verdict[:recent]).to be_nil }
    end

    context 'with the latest 30 days warmer than usual' do
      let(:recent) { build(:climate_recent, starts_on: Date.new(2026, 2, 20), ends_on: Date.new(2026, 3, 21), temp_mean_c: 18.5) }

      it 'says how far above usual, and for which dates' do
        expect(verdict[:recent]).to eq 'In the 30 days from 20 February to 21 March the average was 18.5 °C, ' \
                                       'which is 1.5 °C above the usual 17.0 °C for those dates.'
      end
    end

    context 'with the latest 30 days colder than usual' do
      let(:recent) { build(:climate_recent, temp_mean_c: 15.0) }

      it 'says how far below usual' do
        expect(verdict[:recent]).to include '2.0 °C below the usual 17.0 °C'
      end
    end

    context 'with the latest 30 days as warm as usual' do
      let(:recent) { build(:climate_recent, temp_mean_c: 17.1) }

      it 'says it is close' do
        expect(verdict[:recent]).to include 'close to the usual 17.0 °C'
      end
    end
  end
end
