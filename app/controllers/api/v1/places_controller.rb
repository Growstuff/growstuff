class Api::V1::PlacesController < ApplicationController
  skip_authorize_resource

  api!
  def index
    render json: Member.located.to_json(only: [:id, :login_name, :slug, :location, :latitude, :longitude])
  end

  # GET /places/london.json
  api!
  def show
    @nearby_members = Member.nearest_to(params[:place])
    render json: @nearby_members.to_json(only: [:id, :login_name, :slug, :location, :latitude, :longitude])
  end
end
