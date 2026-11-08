# frozen_string_literal: true

# Typical frost dates for one cell of the weather grid at one threshold, worked out by FrostCalculator
# from its history. Approximate, regional and for entertainment only. Pages read this and never calculate.
class FrostStat < ApplicationRecord
  include OnWeatherGrid

  enum :status, { frost: 'frost', possible: 'possible', rare: 'rare', unknown: 'unknown' }

  validates :threshold_c, :computed_at, presence: true
  validates :threshold_c, uniqueness: { scope: %i(latitude longitude) }

  # The calendar date for one of the day fields, which count days into a frost year, in the frost year named by `year`.
  def date_for(field, year)
    day = public_send(field)
    FrostYear.start_of(year, latitude:) + day.round if day
  end

  def frost_year_of(date)
    FrostYear.containing(date, latitude:)
  end

  # Whether there are dates to show. Rare and unknown cells have none.
  def dated?
    last_frost_median.present?
  end
end
