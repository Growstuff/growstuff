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
