# frozen_string_literal: true

require 'rails_helper'

describe 'Weather on a planting' do
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
    it { expect(page).to have_link 'Open-Meteo.com' }
  end

  context 'without readings' do
    it { expect(page).to have_no_css '#weather' }
  end

  context 'when the garden has no location and the viewer owns it' do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 10, 1)) }

    before do
      sign_in garden.owner
      visit planting_path(planting)
    end

    it { expect(page).to have_link 'Set a garden location to get temperature and rainfall data', href: edit_garden_path(garden) }
  end

  context 'when the garden has no location and the viewer is a visitor' do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations

    it { expect(page).to have_no_link 'Set a garden location to get temperature and rainfall data' }
  end
end
