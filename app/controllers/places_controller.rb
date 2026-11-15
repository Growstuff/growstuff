# frozen_string_literal: true

class PlacesController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!, only: :suggest
  respond_to :html, :json

  MEMBER_FIELDS = %i(id login_name slug location latitude longitude).freeze

  def index
    respond_to do |format|
      format.html
      # json response is whatever we want to map here
      format.json do
        members = Member.kept.located.paginate(page: params[:page]).pluck(*MEMBER_FIELDS).map do |row|
          MEMBER_FIELDS.zip(row).to_h
        end
        render json: members
      end
    end
  end

  # GET /places/london
  # GET /places/london.json
  def show
    @place = params[:place] # used for page title
    @latitude, @longitude = Geocoder.coordinates(@place, params: { limit: 1 }) if @place.present?
    @nearby_members = @latitude && @longitude ? Member.nearest_to_point(@latitude, @longitude) : Member.none
    load_weather(Place.new(@latitude, @longitude)) if @latitude && @longitude && Feature.enabled?(:planting_weather, current_member)
    respond_to do |format|
      format.html # show.html.haml
      format.json do
        render json: @nearby_members.as_json(only: MEMBER_FIELDS)
      end
    end
  end

  # GET /places/suggest.json?q=wellington
  # GET /places/suggest.json?lat=-41.3&lng=174.8
  # Named places to choose from, for the dialog that asks where someone gardens.
  def suggest
    places = if params[:q].present?
               PlaceSuggester.search(params[:q])
             elsif params[:lat].present? && params[:lng].present?
               PlaceSuggester.reverse(Float(params[:lat]), Float(params[:lng]))
             else
               []
             end
    render json: places
  rescue ArgumentError
    render json: [], status: :unprocessable_content
  end

  def search
    if params[:new_place].empty?
      redirect_to places_path, alert: t('messages.invalid_location')
    else
      redirect_to place_path(params[:new_place])
    end
  end

  private

  # The frost and the weather of the place, behind the planting_weather feature switch like those on a planting or a garden.
  def load_weather(place)
    @frost = FrostSeason.for(place)
    @climate = PlaceClimate.for(place)
    ClimateRequest.record(place) if member_signed_in? && !@climate
  end
end
