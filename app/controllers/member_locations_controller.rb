# frozen_string_literal: true

# Saves the place a signed-in member says they garden in. The dialog on the
# home page sends the name and coordinates of a place it found with
# PlacesController#suggest, so there is no second geocode here.
class MemberLocationsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!
  respond_to :json

  def update
    place = location_params
    # Straight to the columns: saving would geocode the name again, and the place already has coordinates.
    columns = { location: place[:name], latitude: place[:latitude], longitude: place[:longitude] }
    current_member.update_columns(columns) # rubocop:disable Rails/SkipsModelValidations
    current_member.gardens.where(location: [nil, '']).update_all(columns) # rubocop:disable Rails/SkipsModelValidations
    render json: { location: place[:name] }
  rescue ArgumentError, ActionController::ParameterMissing
    render json: { errors: { location: ['is not a place we can use'] } }, status: :unprocessable_content
  end

  private

  def location_params
    raw = params.require(:location).permit(:name, :latitude, :longitude)
    name = raw[:name].to_s.squish
    latitude = Float(raw[:latitude])
    longitude = Float(raw[:longitude])
    raise ArgumentError unless name.present? && name.length <= 255 && latitude.between?(-90, 90) && longitude.between?(-180, 180)

    { name:, latitude:, longitude: }
  end
end
