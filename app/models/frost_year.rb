# frozen_string_literal: true

# One frost year's first and last frost for one cell of the weather grid, at one threshold.
# A frost year is the stretch of twelve months that holds one winter whole: the calendar year in the Southern
# Hemisphere, July to June in the Northern, named for the calendar year it ends in. Approximate and regional:
# see FrostCalculator.
class FrostYear < ApplicationRecord
  include OnWeatherGrid

  validates :year, :threshold_c, presence: true
  validates :year, uniqueness: { scope: %i(latitude longitude threshold_c) }

  scope :with_frost, -> { where.not(first_frost: nil) }

  # The first day of a frost year: January in the south, and in the north July before the year's name.
  def self.start_of(year, latitude:)
    latitude.negative? ? Date.new(year, 1, 1) : Date.new(year - 1, 7, 1)
  end

  def self.end_of(year, latitude:)
    start_of(year + 1, latitude:) - 1
  end

  # The frost year a date falls in.
  def self.containing(date, latitude:)
    latitude.negative? || date.month < 7 ? date.year : date.year + 1
  end

  def frost?
    first_frost.present?
  end
end
