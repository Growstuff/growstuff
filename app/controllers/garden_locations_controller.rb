# frozen_string_literal: true

# Saves the place a garden is in, from the same dialog members use to say where they garden. The dialog sends
# the name and coordinates of a place it found with PlacesController#suggest, so there is no second geocode here.
class GardenLocationsController < ApplicationController
  include ChosenPlace

  skip_authorize_resource
  before_action :authenticate_member!
  respond_to :json

  def update
    garden = Garden.friendly.find(params[:garden_slug])
    authorize! :update, garden
    place = chosen_place
    # Straight to the columns: saving would geocode the name again, and the place already has coordinates.
    garden.update_columns(location: place[:name], latitude: place[:latitude], longitude: place[:longitude]) # rubocop:disable Rails/SkipsModelValidations
    render json: { location: place[:name] }
  rescue ArgumentError, ActionController::ParameterMissing
    render json: { errors: { location: ['is not a place we can use'] } }, status: :unprocessable_content
  end
end
