# frozen_string_literal: true

# The place someone chose in the location dialog (see LocationPicker.jsx): a name and coordinates the dialog
# got from PlacesController#suggest. Anything else, such as free text or coordinates off the Earth, is refused,
# so only places we found can be saved.
module ChosenPlace
  extend ActiveSupport::Concern

  private

  # { name:, latitude:, longitude: }, or an ArgumentError / ActionController::ParameterMissing.
  def chosen_place
    raw = params.require(:location).permit(:name, :latitude, :longitude)
    name = raw[:name].to_s.squish
    latitude = Float(raw[:latitude])
    longitude = Float(raw[:longitude])
    raise ArgumentError unless name.present? && name.length <= 255 && latitude.between?(-90, 90) && longitude.between?(-180, 180)

    { name:, latitude:, longitude: }
  end
end
