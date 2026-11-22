# frozen_string_literal: true

require 'rails_helper'

describe ClimateSummary do
  subject(:months) { described_class.new(readings).months }

  let(:readings) do
    {
      Date.new(2025, 7, 1) => { rainfall_mm: 10.0, temp_mean_c: 8.0, temp_max_c: 12.0, temp_min_c: 2.0, soil_temp_c: 7.0 },
      Date.new(2025, 7, 2) => { rainfall_mm: 5.5, temp_mean_c: 10.0, temp_max_c: 15.0, temp_min_c: 1.0, soil_temp_c: 9.0 },
      Date.new(2025, 8, 1) => { rainfall_mm: 0.0, temp_mean_c: 11.0, temp_max_c: 13.0, temp_min_c: 4.0, soil_temp_c: 8.0 }
    }
  end
  let(:july) { months.first }

  it 'has a month for each month with a day' do
    expect(months.map { |month| [month.year, month.month] }).to eq [[2025, 7], [2025, 8]]
  end

  it 'counts the days' do
    expect(july.days).to eq 2
  end

  it 'adds up the rain' do
    expect(july.rain_mm).to eq 15.5
  end

  it 'averages the air temperature' do
    expect(july.temp_mean_c).to eq 9.0
  end

  it 'averages the soil temperature' do
    expect(july.soil_temp_c).to eq 8.0
  end

  it 'finds the hottest day, and when it was' do
    expect(july.attributes.values_at('temp_max_c', 'temp_max_on')).to eq [15.0, Date.new(2025, 7, 2)]
  end

  it 'finds the coldest night, and when it was' do
    expect(july.attributes.values_at('temp_min_c', 'temp_min_on')).to eq [1.0, Date.new(2025, 7, 2)]
  end

  it 'finds the warmest and coldest soil, and when' do
    expect(july.attributes.values_at('soil_temp_max_c', 'soil_temp_max_on', 'soil_temp_min_c', 'soil_temp_min_on'))
      .to eq [9.0, Date.new(2025, 7, 2), 7.0, Date.new(2025, 7, 1)]
  end

  context 'with a day that lacks a figure' do
    let(:readings) { { Date.new(2025, 7, 1) => { rainfall_mm: 3.0 }, Date.new(2025, 7, 2) => { rainfall_mm: 2.0, temp_max_c: 9.0 } } }

    it 'goes by the days that have it' do
      expect(july.attributes.values_at('rain_mm', 'temp_max_c', 'temp_mean_c')).to eq [5.0, 9.0, nil]
    end
  end

  context 'without any days' do
    let(:readings) { {} }

    it { is_expected.to be_empty }
  end
end
