class Api::V1::MembersController < ApplicationController
  def show
    @member = Member.confirmed.find(params[:id])
   
    render json: @member.to_json(only: [:id, :login_name, :bio, :created_at, :slug, :location, :latitude, :longitude])
  end
end