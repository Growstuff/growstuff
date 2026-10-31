# frozen_string_literal: true

# One day's weather for one cell of a weather grid.
class WeatherReading < ApplicationRecord
  # The width of an ERA5 cell, in degrees. Gardens closer together than this share data.
  GRID_DEGREES = 0.25

  validates :latitude, :longitude, :date, :source, presence: true
  validates :date, uniqueness: { scope: %i(latitude longitude) }

  scope :at, ->(latitude, longitude) { where(latitude:, longitude:) }
  scope :between, ->(from, to) { where(date: from..to) }

  # The centre of the grid cell a coordinate falls in.
  def self.grid_point(latitude, longitude)
    [snap(latitude), snap(longitude)]
  end

  def self.snap(degrees)
    ((degrees / GRID_DEGREES).round * GRID_DEGREES).round(2)
  end
end
