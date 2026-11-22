# frozen_string_literal: true

require 'rails_helper'

describe ClimateHelper do
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

  describe '#climate_rain_cards' do
    subject(:cards) { helper.climate_rain_cards(climate) }

    it 'has the usual year, the wettest month and the driest' do
      expect(cards.pluck(:label)).to eq ['Usual year', 'Wettest month on record', 'Driest month on record']
    end

    it 'adds up the usual year' do
      expect(cards.first[:value]).to eq '1,200 mm'
    end
  end

  describe '#climate_record_cards' do
    it 'has a card for each record the months hold' do
      expect(helper.climate_record_cards(climate).size).to eq 4
    end

    it 'says where this year stands' do
      expect(helper.climate_record_cards(climate).first[:note]).to include('This year:')
    end
  end

  describe '#climate_chart' do
    subject(:chart) { Capybara.string(helper.climate_chart(climate, :rain)) }

    it 'has a column for each month' do
      expect(chart).to have_css '.climate-column', count: 12
    end

    it 'draws the usual and this year for the months this year has' do
      expect(chart).to have_css '.climate-bar--year', count: 2
    end

    it 'draws the usual for every month' do
      expect(chart).to have_css '.climate-bar--usual', count: 12
    end

    it 'shows the figure when hovering over a bar' do
      expect(chart).to have_css '.climate-bar--year[title="January, This year: 100 mm"]'
    end

    it 'describes itself for a screen reader' do
      expect(chart).to have_css '.climate-chart[role=img][aria-label*="Jan 100 mm"]'
    end
  end

  describe '#climate_table_rows' do
    subject(:rows) { helper.climate_table_rows(climate, %i(rain air)) }

    it 'has a row for each month' do
      expect(rows.size).to eq 12
    end

    it 'has the usual and this year for each measure' do
      expect(rows.first).to eq ['Jan', '100 mm', '100 mm', '17.0 °C', '17.0 °C']
    end

    it 'shows a month this year has not reached as a dash' do
      expect(rows[11]).to eq ['Dec', '100 mm', '–', '17.0 °C', '–']
    end
  end
end
