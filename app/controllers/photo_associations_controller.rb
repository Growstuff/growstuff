# frozen_string_literal: true

class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  def destroy
    raise "Photos not supported" unless Photo::PHOTO_CAPABLE.include? item_class

    @photo = Photo.find_by!(id: params[:photo_id], owner: current_member)
    @item = PhotoAssociation.item(item_id, item_class)
    @item.photos.delete(@photo)
    # @photo.destroy_if_unused
    respond_with(@photo)
  end

  private

  def item_class
    params[:type].capitalize
  end

  def item_id
    params[:id]
  end
end
