# frozen_string_literal: true

require 'rails_helper'

describe 'Weather on a planting', flipper: :planting_weather do
  let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 10, 1)) }

  before { visit planting_path(planting) }

  context 'with readings for the garden' do
    let(:planting) do
      create(:planting, garden:, owner: garden.owner, crop: create(:crop, median_lifespan: 100), planted_at: Date.new(2026, 10, 1)).tap do
        create(:weather_reading, date: Date.new(2026, 10, 1), rainfall_mm: 4.0)
      end
    end

    it { expect(page).to have_css '#weather', text: '4 mm' }
    it { expect(page).to have_link 'Weather data by Open-Meteo.com', href: 'https://open-meteo.com/' }
    it { expect(page).to have_link 'CC BY 4.0', href: 'https://creativecommons.org/licenses/by/4.0/' }
  end

  context 'with only last year\'s readings to expect' do
    let(:today) { Time.zone.today }
    let(:planting) do
      create(:planting, garden:, owner: garden.owner, crop: create(:crop, median_lifespan: 100), planted_at: today - 1).tap do
        create(:weather_reading, date: (today + 5).prev_year, rainfall_mm: 4.0)
      end
    end

    it { expect(page).to have_css '#weather rect.weather-expected' }
    it { expect(page).to have_no_text "We're loading the weather" }
    it { expect(page).to have_no_css '.weather-summary' }
  end

  context 'without readings' do
    it { expect(page).to have_no_css '#weather' }
    it { expect(page).to have_text "We're loading the weather for this garden's area" }
  end

  context 'when the garden has no location and the viewer owns it' do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 10, 1)) }

    before do
      sign_in garden.owner
      visit planting_path(planting)
    end

    it { expect(page).to have_button 'Set a garden location to get temperature and rainfall data' }

    context 'when they open the prompt' do
      before { click_button 'Set a garden location to get temperature and rainfall data' }

      it { expect(page).to have_css '[role=dialog]', text: 'Where is this garden?' }
      it { expect(page).to have_no_button(/from my profile/) }
    end
  end

  context 'when the owner has a place on their profile' do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 10, 1)) }

    before do
      garden.owner.update_columns(location: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772) # rubocop:disable Rails/SkipsModelValidations
      sign_in garden.owner
      visit planting_path(planting)
      click_button 'Set a garden location to get temperature and rainfall data'
    end

    it { expect(page).to have_button 'Use Wellington, New Zealand from my profile' }
  end

  context 'when the garden has no location and the viewer is a visitor' do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations

    it { expect(page).to have_no_button 'Set a garden location to get temperature and rainfall data' }
  end

  context 'when the feature is switched off', flipper: [] do
    let(:planting) do
      create(:planting, garden:, owner: garden.owner, crop: create(:crop, median_lifespan: 100), planted_at: Date.new(2026, 10, 1)).tap do
        create(:weather_reading, date: Date.new(2026, 10, 1), rainfall_mm: 4.0)
      end
    end

    it { expect(page).to have_no_css '#weather' }
  end

  context 'when the planting is still in the nursery' do
    let(:garden) { create(:garden, nursery: true).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) do
      create(:planting, garden:, owner: garden.owner, crop: create(:crop, median_lifespan: 100), planted_at: Date.new(2026, 10, 1)).tap do
        create(:weather_reading, date: Date.new(2026, 10, 1), rainfall_mm: 4.0)
      end
    end

    it { expect(page).to have_no_css '#weather' }
  end

  context 'when a nursery has no location and the viewer owns it' do
    let(:garden) { create(:garden, nursery: true).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 10, 1)) }

    before do
      sign_in garden.owner
      visit planting_path(planting)
    end

    it { expect(page).to have_no_button 'Set a garden location to get temperature and rainfall data' }
  end
end
