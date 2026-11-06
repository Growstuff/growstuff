# frozen_string_literal: true

# Typical frost dates for one cell of the weather grid at one threshold, worked out by FrostCalculator
# from its history. Approximate, regional and for entertainment only. Pages read this and never calculate.
class FrostStat < ApplicationRecord
  STATUSES = %w(frost possible rare unknown).freeze
  # The day fields count days into the frost year, which FrostCalculator.frost_year_start dates.
  DAY_FIELDS = %i(first_frost_median first_frost_p10 last_frost_median last_frost_p90).freeze

  enum :status, STATUSES.index_by(&:itself)

  validates :latitude, :longitude, :threshold_c, :computed_at, presence: true
  validates :threshold_c, uniqueness: { scope: %i(latitude longitude) }

  scope :at, ->(latitude, longitude) { where(latitude:, longitude:) }

  # The calendar date for one of the day fields, in the frost year named by `year`.
  def date_for(field, year)
    day = public_send(field)
    return if day.nil?

    FrostCalculator.frost_year_start(year, latitude:) + day.round
  end

  # Whether there are dates to show. Rare and unknown cells have none.
  def dated?
    last_frost_median.present?
  end
end
