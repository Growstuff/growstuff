class PlacesController < ApplicationController
  skip_authorize_resource

  def index
    respond_to do |format|
      format.html
    end
  end

  # GET /places/london
  # GET /places/london.json
  def show
    @place = params[:place]

    if !params[:distance].blank?
      @distance = params[:distance]
    else
      @distance = 100
    end

    if params[:units] == "mi"
      @units = :mi
    else
      @units = :km
    end

    location = Nominatim.geocode(@place)
    if location
      @latitude = location[:latitude]
      @longitude = location[:longitude]
      if @distance
        @sw_lat, @sw_lng, @ne_lat, @ne_lng = Geocoder::Calculations.bounding_box(
          [@latitude, @longitude],
          @distance,
          options = { :units => @units }
        )
      end
    else
      @latitude, @longitude = [0, 0]
      @sw_lat, @sw_lng, @ne_lat, @ne_lng = [0,0,0,0]
      flash[:alert] = "Sorry, our map provider can't find this location."
    end

    @nearby_members = @place ? Member.near(@place, @distance, :units => @units) : []

    respond_to do |format|
      format.html # show.html.haml
    end
  end

  def search
    respond_to do |format|
      format.html do
        redirect_to place_path(params[:new_place], :units => params[:units], :distance => params[:distance])
      end
    end
  end

end
