# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show without a planting date', flipper: :planting_weather do
  let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: nil) }

  before do
    create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
    get planting_path(planting)
  end

  it 'shows the page' do
    expect(response).to have_http_status(:ok)
  end

  it 'has no frost section, which needs the day it went in' do
    expect(Capybara.string(response.body)).to have_no_css('.frost-section')
  end
end
