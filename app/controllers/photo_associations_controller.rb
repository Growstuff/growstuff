# frozen_string_literal: true

class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  def destroy
    raise ActiveRecord::RecordNotFound unless Photo::PHOTO_CAPABLE.include?(item_class)

    @photo = Photo.find(params[:photo_id])
    @item = item_class.constantize.find(params[:id])

    authorize_deletion!

    @item.photos.delete(@photo)
    respond_with(@photo)
  end

  private

  def item_class
    params[:type].to_s.classify
  end

  def authorize_deletion!
    return if @photo.owner_id == current_member.id
    return if can?(:edit, @item) || can?(:update, @item) || can?(:destroy, @item)
    return if current_member.role?(:admin)

    raise ActiveRecord::RecordNotFound
  end
end
