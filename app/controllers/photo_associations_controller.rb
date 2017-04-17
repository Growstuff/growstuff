class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  def destroy
    @photo = Photo.find(params[:photo_id])
    collection = Growstuff::Constants::PhotoModels.get_relation(@photo, params[:type])
    item_class = Growstuff::Constants::PhotoModels.get_item(params[:type])
    @item = item_class.find_by!(id: params[:id], owner_id: current_member.id)
    collection.delete(@item) if owner_matches?
    respond_with(@photo)
  end

  def owner_matches?
    @photo.owner == current_member && @item.owner == current_member
  end
end
