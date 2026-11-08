# frozen_string_literal: true

require 'rails_helper'

describe PlacesController, '#show frost dates', flipper: :planting_weather do
  subject(:page) { Capybara.string(response.body) }

  let(:place) { 'Wellington' }

  before do
    Geocoder::Lookup::Test.add_stub(place, [{ 'coordinates' => [-41.29, 174.78] }])
    get place_path(place)
  end

  context 'without frost dates for the place' do
    it { is_expected.to have_no_css('.frost-section') }
  end

  context 'when the place has frost dates' do
    before do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      get place_path(place)
    end

    it { is_expected.to have_css('.frost-section .frost-timeline') }

    it 'draws it as a record page does, so the heading bar is the lid' do
      expect(page).to have_css('.record-page .frost-section')
    end
  end

  context 'when the weather feature is off', flipper: [] do
    before do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      get place_path(place)
    end

    it { is_expected.to have_no_css('.frost-section') }
  end

  context 'when the place has months of weather' do
    before do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      [Time.zone.today.year - 1, Time.zone.today.year].each { |year| create(:climate_month, year:, month: 1) }
      get place_path(place)
    end

    it { is_expected.to have_css('.climate-rainfall .climate-chart') }
    it { is_expected.to have_css('.climate-temperature .climate-chart', count: 2) }

    it 'puts the weather above the frost' do
      expect(response.body.index('climate-rainfall')).to be < response.body.index('frost-section')
    end
  end

  context 'without months of weather' do
    it { is_expected.to have_no_css('.climate-section') }
  end
end
