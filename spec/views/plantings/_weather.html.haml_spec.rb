# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_weather' do
  let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 6, 15)) }
  let(:status) { 'frost' }

  before do
    create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C, status:)
    render partial: 'plantings/weather', locals: { planting:, readings: [], expected: [] }
  end

  it 'shows the frost danger heading' do
    expect(rendered).to have_css '.frost-danger h3', text: 'Frost danger'
  end

  it 'shows the last frost danger' do
    expect(rendered).to have_content 'about 8 September'
  end

  it 'shades the usual frost danger on the rain chart' do
    expect(rendered).to have_css '.weather-rain rect.weather-frost'
  end

  it 'explains the bands' do
    expect(rendered).to have_content 'The blue bands are the usual frost danger'
  end

  it 'says it is a guess' do
    expect(rendered).to have_content 'Alpha – a guess, for entertainment only'
  end

  it 'does not warn about patchy dates for a common frost' do
    expect(rendered).to have_no_content 'only comes in some years'
  end

  context 'with frost in only some years' do
    let(:status) { 'possible' }

    it 'warns the dates are a rough guide' do
      expect(rendered).to have_content 'only comes in some years'
    end
  end

  context 'with little frost' do
    let(:status) { 'rare' }

    before do
      FrostStat.update_all(first_frost_median: nil, last_frost_median: nil) # rubocop:disable Rails/SkipsModelValidations
      render partial: 'plantings/weather', locals: { planting: planting.reload, readings: [], expected: [] }
    end

    it 'says frost danger is rare' do
      expect(rendered).to have_content 'Frost danger is rare here'
    end
  end

  context 'without frost dates for the cell' do
    before do
      FrostStat.delete_all
      render partial: 'plantings/weather', locals: { planting: planting.reload, readings: [], expected: [] }
    end

    it 'shows nothing about frost' do
      expect(rendered).to have_no_css '.frost-danger'
    end
  end
end
