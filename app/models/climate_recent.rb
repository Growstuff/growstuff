# frozen_string_literal: true

# How warm the latest 30 days were for one cell of the weather grid: their average air temperature and the dates they
# cover. See ClimateUpdater. Approximate and regional.
class ClimateRecent < ApplicationRecord
  include OnWeatherGrid

  # How many days it looks back over.
  DAYS = 30

  validates :starts_on, :ends_on, :days, presence: true
  validates :latitude, uniqueness: { scope: :longitude }

  # The row for the latest of the days, as ClimateUpdater fetched them: { Date => { temp_mean_c: number, ... } }.
  # Unsaved, without the cell, or nil when none of the last DAYS days has an air temperature.
  def self.from_days(readings)
    last = readings.select { |_, day| day[:temp_mean_c] }.keys.max
    return unless last

    first = last - (DAYS - 1)
    means = readings.filter_map { |date, day| day[:temp_mean_c] if date.between?(first, last) }
    new(starts_on: first, ends_on: last, days: means.size, temp_mean_c: (means.sum / means.size).round(1))
  end
end
