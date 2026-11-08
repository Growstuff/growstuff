# frozen_string_literal: true

# A place that sits in a cell of the weather grid: a garden, and the plantings in it through their garden. It has
# the weather readings and the typical frost dates of that cell. See OnWeatherGrid.
module WeatherLocated
  extend ActiveSupport::Concern

  def weather_located?
    latitude.present? && longitude.present?
  end

  # The centre of the weather grid cell this place is in, as [latitude, longitude].
  def weather_cell
    WeatherReading.grid_point(latitude, longitude)
  end

  # The typical frost danger dates for this place's weather cell, as ClimateUpdater saved them, or nil when
  # it has no location or they aren't worked out yet.
  def frost_danger
    return unless weather_located?

    FrostStat.at(*weather_cell).find_by(threshold_c: FrostCalculator::FROST_DANGER_C)
  end
end
