# frozen_string_literal: true

require 'rails_helper'

describe HomeController, '#index weather invitation', flipper: :planting_weather do
  subject(:page) { Capybara.string(response.body) }

  let(:member) { create(:london_member) }

  before do
    Rails.cache.clear
    sign_in member
  end

  context 'with a location and no weather yet' do
    before { get root_path }

    it { is_expected.to have_css('.weather-invitation .weather-invitation-card', count: 3) }
    it { is_expected.to have_css('.weather-invitation', text: 'loading the weather history for your garden in Greenwich') }
  end

  context 'with frost dates for the place' do
    before do
      create(:frost_stat, latitude: 51.5, longitude: 0.0, threshold_c: FrostCalculator::FROST_DANGER_C)
      get root_path
    end

    it { is_expected.to have_link(href: place_path('Greenwich, UK')) }
    it { is_expected.to have_css('.weather-invitation-icon--frost') }
  end

  context 'without a location', :aggregate_failures do
    let(:member) { create(:member, location: nil, latitude: nil, longitude: nil) }

    before { get root_path }

    it { is_expected.to have_css('.weather-invitation .weather-invitation-card', count: 3) }
  end

  context 'when the weather feature is off', flipper: [] do
    before { get root_path }

    it { is_expected.to have_no_css('.weather-invitation') }
  end
end
