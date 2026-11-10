# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_weather' do
  include ActiveSupport::Testing::TimeHelpers

  let(:today) { Time.zone.today }
  let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  let(:crop) { create(:crop, median_lifespan: 100, ecocrop_record: create(:ecocrop_data, topmn: 10, topmx: 24, tmin: 4, tmax: 30)) }
  let(:planting) { create(:planting, crop:, garden:, owner: garden.owner, planted_at: today - 10) }
  let(:readings) { [build(:weather_reading, date: today - 6, temp_max_c: 18, temp_min_c: 12)] }

  # The test environment has caching off, so turn it on here: without it these examples pass whatever the cache key is.
  around do |example|
    store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = store
  end

  before { controller.perform_caching = true }

  def render_weather(readings: self.readings)
    render partial: 'plantings/weather', locals: { planting:, readings:, expected: [] }
  end

  it 'shows the climate notes' do
    expect(render_weather).to have_css '.weather-note'
  end

  it 'works the notes out once for the same readings' do
    expect(view).to receive(:weather_climate_notes).once.and_call_original
    2.times { render_weather }
  end

  it 'works them out again when a newer reading arrives' do
    render_weather
    expect(view).to receive(:weather_climate_notes).once.and_call_original
    render_weather(readings: readings + [build(:weather_reading, date: today - 5, temp_max_c: 40, temp_min_c: 20)])
  end

  it 'works them out again the next day' do
    render_weather
    expect(view).to receive(:weather_climate_notes).once.and_call_original
    travel_to(today + 1) { render_weather }
  end

  it 'works them out again when the crop changes' do
    render_weather
    crop.update!(name: 'a new name')
    expect(view).to receive(:weather_climate_notes).once.and_call_original
    render_weather
  end
end
