# frozen_string_literal: true

# A cell of the weather grid someone asked to see the climate of, by setting their location there or by looking at a place
# we hold none for. ClimateUpdater fetches these cells before any others and then removes the request. Cells, not places,
# so a thousand people asking for one city is one request.
class ClimateRequest < ApplicationRecord
  include OnWeatherGrid

  validates :requested_at, presence: true

  # Asks for the climate of a place, unless it is unlocated or we already hold it. Asking again keeps the first time.
  def self.record(place)
    return unless place.weather_located?

    latitude, longitude = place.weather_cell
    return if ClimateMonth.at(latitude, longitude).exists?

    now = Time.current
    row = { latitude:, longitude:, requested_at: now, created_at: now, updated_at: now }
    upsert(row, unique_by: :index_climate_requests_on_cell, on_duplicate: :skip) # rubocop:disable Rails/SkipsModelValidations
  end

  # Asks for the cell of each located member, the most recently active first so they are fetched first. Members near each
  # other share a cell, so it is asked for once, and a cell we hold weather for is left out. Returns how many cells were added.
  def self.record_members(members = Member.kept.located)
    before = count
    cells = members.order(Arel.sql('GREATEST(last_sign_in_at, created_at) DESC NULLS LAST')).pluck(:latitude, :longitude)
    cells.uniq { |latitude, longitude| WeatherReading.grid_point(latitude, longitude) }
      .each { |latitude, longitude| record(Place.new(latitude, longitude)) }
    count - before
  end

  # The cells still waiting, the one that has waited longest first, as [latitude, longitude, when asked].
  def self.waiting
    rows = order(:requested_at).pluck(:latitude, :longitude, :requested_at)
    rows.reject { |latitude, longitude,| ClimateMonth.at(latitude, longitude).exists? }
  end

  def self.fulfilled(latitude, longitude)
    where(latitude:, longitude:).delete_all
  end
end
