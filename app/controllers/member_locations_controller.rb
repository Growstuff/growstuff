# frozen_string_literal: true

# Saves the place a signed-in member says they garden in. The dialog on the
# home page sends the name and coordinates of a place it found with
# PlacesController#suggest, so there is no second geocode here.
class MemberLocationsController < ApplicationController
  include ChosenPlace

  skip_authorize_resource
  before_action :authenticate_member!
  respond_to :json

  def update
    place = chosen_place
    # Straight to the columns: saving would geocode the name again, and the place already has coordinates.
    current_member.update_columns(place) # rubocop:disable Rails/SkipsModelValidations
    current_member.gardens.where(location: [nil, '']).update_all(place) # rubocop:disable Rails/SkipsModelValidations
    render json: { location: place[:location] }
  end
end
