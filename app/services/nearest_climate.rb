# frozen_string_literal: true

# The weather we hold that is nearest to a point, for a visitor who hasn't told us where they garden: the ClimateMonth cell
# closest to it, how far that is and the SeasonalClimate there. It holds the working out and no text.
class NearestClimate
  EARTH_RADIUS_KM = 6371.0
  # Beyond this the weather is too far off to describe the visitor's own garden.
  FAR_KM = 30

  attr_reader :latitude, :longitude, :distance_km

  # The nearest held weather to the point, or nil when we hold none or the point isn't a place on Earth.
  def self.to(latitude, longitude)
    return unless latitude.is_a?(Numeric) && longitude.is_a?(Numeric) && latitude.between?(-90, 90) && longitude.between?(-180, 180)

    cell = ClimateMonth.distinct.pluck(:latitude, :longitude).min_by { |lat, lng| kilometres(latitude, longitude, lat, lng) }
    new(*cell, kilometres(latitude, longitude, *cell)) if cell
  end

  # Great-circle distance between two points, in km.
  def self.kilometres(lat1, lng1, lat2, lng2)
    rad = Math::PI / 180
    a = (Math.sin((lat2 - lat1) * rad / 2)**2) +
        (Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * (Math.sin((lng2 - lng1) * rad / 2)**2))
    2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a))
  end

  def initialize(latitude, longitude, distance_km)
    @latitude = latitude
    @longitude = longitude
    @distance_km = distance_km
  end

  # What the cell is called, such as "Wellington, New Zealand", or nil when we can't tell. Only the cell's centre is looked up,
  # never the visitor's own position.
  def place_name
    @place_name ||= PlaceSuggester.reverse(latitude, longitude).first&.fetch(:name)
  end

  def far?
    distance_km > FAR_KM
  end

  def climate(today: Time.zone.today)
    SeasonalClimate.new(ClimateMonth.at(latitude, longitude).to_a, latitude:, today:)
  end
end
