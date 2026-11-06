# frozen_string_literal: true

# One frost year's first and last frost for one cell of the weather grid, at one threshold.
# Approximate and regional: see FrostCalculator.
class FrostYear < ApplicationRecord
  validates :latitude, :longitude, :year, :threshold_c, presence: true
  validates :year, uniqueness: { scope: %i(latitude longitude threshold_c) }

  scope :at, ->(latitude, longitude) { where(latitude:, longitude:) }
  scope :with_frost, -> { where.not(first_frost: nil) }
end
