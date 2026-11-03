# frozen_string_literal: true

# The place someone chose in the location dialog (see LocationPicker.jsx): a name and coordinates the dialog
# got from PlacesController#suggest. Anything else, such as free text or coordinates off the Earth, is refused,
# so only places we found can be saved.
module ChosenPlace
  extend ActiveSupport::Concern

  # Raised for anything the dialog could not have sent.
  class Invalid < StandardError; end

  included do
    rescue_from Invalid, ActionController::ParameterMissing do
      render json: { errors: { location: ['is not a place we can use'] } }, status: :unprocessable_content
    end
  end

  private

  # The columns to save: { location:, latitude:, longitude: }.
  def chosen_place
    raw = params.require(:location).permit(:name, :latitude, :longitude)
    name = raw[:name].to_s.squish
    latitude = Float(raw[:latitude])
    longitude = Float(raw[:longitude])
    raise Invalid unless name.present? && name.length <= 255 && latitude.between?(-90, 90) && longitude.between?(-180, 180)

    { location: name, latitude:, longitude: }
  rescue ArgumentError, TypeError
    raise Invalid
  end
end
