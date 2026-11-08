# frozen_string_literal: true

# The front page's invitation to see the weather at a member's own place: whether to show it, which of its three states
# it is in, and the frost and climate headlines for the place. It holds the working out and no text.
#
# :no_location  the member hasn't said where they garden, so it shows what they would get
# :loading      they have, but none of the weather for the place is saved yet
# :ready        there are headlines to show
class WeatherInvitation
  attr_reader :frost, :climate

  def initialize(member, today: Time.zone.today)
    @member = member
    place = Place.new(member.latitude, member.longitude)
    return unless member.located?

    @frost = FrostSeason.for(place, today:)
    @climate = PlaceClimate.for(place, today:)
  end

  # The state of the invitation: :no_location, :loading or :ready.
  def state
    if !@member.located? then :no_location
    elsif @frost || @climate then :ready
    else :loading
    end
  end

  # The name of the place, such as Wellington.
  def place_name
    @member.location_place
  end

  # Whether the front page shows it: the weather feature is switched on.
  def self.enabled?
    Feature.enabled?(:planting_weather)
  end
end
