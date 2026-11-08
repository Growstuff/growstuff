# frozen_string_literal: true

# One month of weather for one cell of the weather grid: the rain, the air and soil temperatures and the extremes, from
# that month's daily figures. See ClimateSummary. Approximate and regional.
class ClimateMonth < ApplicationRecord
  include OnWeatherGrid

  validates :year, :month, :days, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :year, uniqueness: { scope: %i(latitude longitude month) }
end
