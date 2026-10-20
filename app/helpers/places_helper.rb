# frozen_string_literal: true

module PlacesHelper
  # Read by app/javascript/site/places.js from the #placesmap element.
  def places_map_data
    {
      marker_icon: image_path('spade-marker.svg'),
      user_agent_email: Rails.env.test? ? 0 : Rails.application.config.user_agent_email
    }
  end
end
