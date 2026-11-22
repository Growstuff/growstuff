# frozen_string_literal: true

module PlacesHelper
  # Read by app/javascript/site/places.js from the #placesmap element. latitude and longitude, where we have them, are
  # where the map is centred, so the browser doesn't have to look the place up itself.
  def places_map_data(latitude: nil, longitude: nil)
    {
      marker_icon:      image_path('spade-marker.svg'),
      user_agent_email: Rails.env.test? ? 0 : Rails.application.config.user_agent_email,
      latitude:,
      longitude:
    }.compact
  end
end
