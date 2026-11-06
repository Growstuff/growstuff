# frozen_string_literal: true

class PhotoAssociationsController < ApplicationController
  before_action :authenticate_member!
  respond_to :json, :html

  # Says what part of the item the photo is of, as `label`: the front or back of
  # a seed packet, or nothing at all.
  def update
    @photo = Photo.find(params[:photo_id])
    @item = find_item
    raise ActiveRecord::RecordNotFound unless can?(:update, @item)

    association = @item.photo_associations.find_by!(photo: @photo)
    if association.update(label: params[:label])
      redirect_back_or_to @item, notice: t('.updated')
    else
      redirect_back_or_to @item, alert: association.errors.full_messages.to_sentence
    end
  end

  def destroy
    @photo = Photo.find(params[:photo_id])
    @item = find_item

    authorize_deletion!

    @item.photos.delete(@photo)
    respond_with(@photo)
  end

  private

  def item_class
    params[:type].to_s.classify
  end

  def find_item
    raise ActiveRecord::RecordNotFound unless Photo::PHOTO_CAPABLE.include?(item_class)

    item_class.constantize.find(params[:id])
  end

  def authorize_deletion!
    return if @photo.owner_id == current_member.id
    return if can?(:edit, @item) || can?(:update, @item) || can?(:destroy, @item)
    return if current_member.role?(:admin)

    raise ActiveRecord::RecordNotFound
  end
end
