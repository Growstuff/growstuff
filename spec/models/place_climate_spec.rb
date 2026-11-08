# frozen_string_literal: true

require 'rails_helper'

describe PlaceClimate do
  subject(:climate) { described_class.new(months, today:) }

  let(:today) { Date.new(2026, 3, 20) }
  # Two past years of every month: 100 mm of rain, 17 degrees in the air and 15 in the soil, with July the coldest.
  let(:past) do
    [2024, 2025].flat_map do |year|
      (1..12).map do |month|
        build(:climate_month, year:, month:, days: Time.days_in_month(month, year), rain_mm: month == 7 ? 150.0 : 100.0,
                              temp_mean_c: month == 7 ? 9.0 : 17.0, soil_temp_c: 15.0,
                              temp_max_c: 25.0 + month, temp_max_on: Date.new(year, month, 5),
                              temp_min_c: 10.0 - month, temp_min_on: Date.new(year, month, 9))
      end
    end
  end
  # This year so far: January and February whole, and 15 days of March.
  let(:this_year) do
    [[1, 31, 100.0, 18.0], [2, 28, 80.0, 18.0], [3, 15, 60.0, 16.0]].map do |month, days, rain, air|
      build(:climate_month, year: 2026, month:, days:, rain_mm: rain, temp_mean_c: air, soil_temp_c: 15.0,
                            temp_max_c: 20.0, temp_max_on: Date.new(2026, month, 3))
    end
  end
  let(:months) { past + this_year }

  it 'counts the complete years it goes by' do
    expect(climate.years_held).to eq 2
  end

  it 'has this year' do
    expect(climate).to be_this_year
  end

  describe '#usual' do
    it 'averages a month over the years held' do
      expect(climate.usual(:rain)[7]).to eq 150.0
    end

    it 'leaves this year out' do
      expect(climate.usual(:air)[3]).to eq 17.0
    end
  end

  describe '#this_year' do
    it 'has the months so far' do
      expect(climate.this_year(:rain)).to eq(1 => 100.0, 2 => 80.0, 3 => 60.0)
    end
  end

  describe 'the rain' do
    it 'adds up the usual year' do
      expect(climate.usual_rain_for_year).to eq 1250.0
    end

    it 'adds up this year so far' do
      expect(climate.rain_this_year).to eq 240.0
    end

    it 'adds up what usually falls by now, scaling the month the data stops in' do
      expect(climate.usual_rain_to_date).to be_within(0.1).of(248.4)
    end

    it 'is close to usual when this year is about as wet' do
      expect(climate.rain_comparison).to eq :close
    end

    context 'with a dry year' do
      let(:this_year) { [build(:climate_month, year: 2026, month: 1, days: 31, rain_mm: 40.0)] }

      it { expect(climate.rain_comparison).to eq :drier }
    end

    context 'with a wet year' do
      let(:this_year) { [build(:climate_month, year: 2026, month: 1, days: 31, rain_mm: 200.0)] }

      it { expect(climate.rain_comparison).to eq :wetter }
    end
  end

  describe 'the air temperature' do
    it 'averages this year so far, weighted by the days' do
      expect(climate.air_this_year).to eq 17.6
    end

    it 'finds what it usually is by now' do
      expect(climate.air_usual_to_date).to eq 17.0
    end

    it 'finds the difference' do
      expect(climate.air_difference).to eq 0.6
    end

    it 'is a little warmer than usual for a difference under a degree' do
      expect(climate.air_comparison).to eq :a_little_warmer
    end

    context 'with a year over a degree colder' do
      let(:this_year) { [build(:climate_month, year: 2026, month: 1, days: 31, temp_mean_c: 15.0)] }

      it { expect(climate.air_comparison).to eq :cooler }
    end

    context 'with a year as warm as usual' do
      let(:this_year) { [build(:climate_month, year: 2026, month: 1, days: 31, temp_mean_c: 17.1)] }

      it { expect(climate.air_comparison).to eq :close }
    end
  end

  describe '#extreme_month' do
    it 'finds the wettest month' do
      expect(climate.extreme_month(:rain, :most)).to eq [7, 150.0]
    end

    it 'finds the coldest month' do
      expect(climate.extreme_month(:air, :least)).to eq [7, 9.0]
    end
  end

  describe '#record' do
    it 'finds the hottest day, and when, the first of equal days winning' do
      expect(climate.record(:hottest_day).to_a).to eq [37.0, Date.new(2024, 12, 5)]
    end

    it 'finds the coldest night, and when' do
      expect(climate.record(:coldest_night).to_a).to eq [-2.0, Date.new(2024, 12, 9)]
    end

    it 'finds this year\'s own hottest day' do
      expect(climate.record_this_year(:hottest_day).value).to eq 20.0
    end
  end

  context 'with no months this year' do
    let(:this_year) { [] }

    it 'has no comparison' do
      expect(climate.rain_comparison).to be_nil
    end
  end

  describe '.for' do
    let(:place) { Place.new(-41.29, 174.78) }

    it 'is nil with no months for the place' do
      expect(described_class.for(place)).to be_nil
    end

    it 'is a climate with them' do
      create(:climate_month, latitude: -41.25, longitude: 174.75)
      expect(described_class.for(place)).to be_a described_class
    end
  end
end
