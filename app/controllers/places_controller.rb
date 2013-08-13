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

    json = open(URI.escape("http://nominatim.openstreetmap.org/search/#{@place}?format=json&limit=1")).read()
    location = JSON.parse(json)

    if location && location[0]
      puts location[0].to_yaml
      @latitude = location[0]['lat']
      @longitude = location[0]['lon']

      @sw_lat, @sw_lng, @ne_lat, @ne_lng = Geocoder::Calculations.bounding_box(
        [@latitude, @longitude],
        @distance,
        options = { :units => @units }
      )
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
