class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  def destroy
    @photo = Photo.find_by!(id: params[:photo_id], owner: current_member)
    collection = Growstuff::Constants::PhotoModels.get_relation(@photo, params[:type])
    item_class = Growstuff::Constants::PhotoModels.get_item(params[:type])
    @item = item_class.find_by!(id: params[:id], owner_id: current_member.id)
    collection.delete(@item)
    respond_with(@photo)
  end

  def owner_matches?
    @photo.owner == current_member && @item.owner == current_member
  end
end
