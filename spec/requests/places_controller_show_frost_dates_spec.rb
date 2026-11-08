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
  end

  context 'when the weather feature is off', flipper: [] do
    before do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      get place_path(place)
    end

    it { is_expected.to have_no_css('.frost-section') }
  end
end
