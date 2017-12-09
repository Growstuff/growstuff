class PlacesController < ApplicationController
  skip_authorize_resource
  respond_to :html, :json

  def index
    respond_to do |format|
      format.html
      # json response is whatever we want to map here
      format.json do
        render json: Member.located.to_json(only: %i(
                                              id login_name slug location latitude longitude
                                            ))
      end
    end
  end

  # GET /places/london
  # GET /places/london.json
  def show
    @place = params[:place] # used for page title
    @nearby_members = Member.nearest_to(params[:place])
    respond_to do |format|
      format.html # show.html.haml
      format.json do
        render json: @nearby_members.to_json(only: %i(
                                               id login_name slug location latitude longitude
                                             ))
      end
    end
  end

  def search
    if params[:new_place].empty?
      redirect_to places_path, alert: 'Please enter a valid location'
    else
      redirect_to place_path(params[:new_place])
    end
  end
end
