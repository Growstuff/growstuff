class PlacesController < ApplicationController
  skip_authorize_resource

  def index
    respond_to do |format|
      format.html
      # json response is whatever we want to map here
      format.json { render :json => Member.all.to_json(:only => [:id, :login_name, :location, :latitude, :longitude]) }
    end
  end

  # GET /places/london
  # GET /places/london.json
  def show
    @place = params[:place]

    # calculate location just once, rather than using @place later
    # sadly we also do this in the javascript, which means we're making
    # the same query twice, but I'm not sure how to avoid that.
    location = Geocoder.search(Geocoder::Query.new(@place, :params => {limit: 1}))

    @nearby_members = []
    if location
      coords = [location[0].data['lat'], location[0].data['lon']]
      @nearby_members = Member.near(coords, 1000, :units => :km).sort_by { |x| x.distance_from(coords) }.first(30)
    end

    respond_to do |format|
      format.html # show.html.haml
      format.json { render :json => @nearby_members.to_json(:only => [:id, :login_name, :location, :latitude, :longitude]) }
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
