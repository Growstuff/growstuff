# frozen_string_literal: true

# A point on the map, such as a place someone searched for. It sits in a cell of the weather grid, so it has frost dates.
Place = Struct.new(:latitude, :longitude) do
  include WeatherLocated
end
