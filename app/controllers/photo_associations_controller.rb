class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  def destroy
    @photo = Photo.find(params[:photo_id])
    if params[:type] == 'planting'
      @planting = Planting.find(params[:planting_id])
      @photo.plantings.delete(@planting) if @planting.owner == current_member && @photo.owner == current_member
    end
    respond_with(@photo)
  end
end
