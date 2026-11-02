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

  # Their location is optional, so it can be taken back.
  def destroy
    current_member.update_columns(location: nil, latitude: nil, longitude: nil) # rubocop:disable Rails/SkipsModelValidations
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_back_or_to edit_member_registration_path, notice: t('messages.location_cleared') }
    end
  end
end
