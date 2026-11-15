# frozen_string_literal: true

# A row for one cell of the weather grid, named by the latitude and longitude of the cell's centre.
# Gardens in the same cell share their rows. See WeatherReading.grid_point.
module OnWeatherGrid
  extend ActiveSupport::Concern

  included do
    validates :latitude, :longitude, presence: true

    scope :at, ->(latitude, longitude) { where(latitude:, longitude:) }
  end
end
