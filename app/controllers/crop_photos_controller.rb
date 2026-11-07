# frozen_string_literal: true

# Lets a crop wrangler find and add a photo to a crop from the crop's page, by pasting the
# address of a public, Creative Commons photo on Flickr. The photo needs no planting,
# seed or harvest. It is read with Flickr's public API, so it belongs to cropbot, as the
# crop's own photos are the site's rather than a member's, and credits its photographer.
class CropPhotosController < ApplicationController
  before_action :authenticate_member!

  # Photos on Flickr that might suit the crop, for the wrangler to pick from.
  def new
    @crop = Crop.find(params[:crop_slug])
    authorize! :edit, @crop
    @query = params[:q].presence || @crop.name
    @results = FlickrPublicPhoto.search(@query, page: params[:page].to_i.clamp(1, 20))
  rescue FlickrPublicPhoto::Rejected
    redirect_to crop_path(@crop), alert: t('crop_photos.create.unavailable')
  end

  def create
    crop = Crop.find(params[:crop_slug])
    authorize! :edit, crop

    attributes = FlickrPublicPhoto.new(params[:url]).attributes
    attributes[:title] ||= crop.name
    photo = Photo.find_or_initialize_by(source: 'flickr', source_id: attributes[:source_id])
    photo.assign_attributes(attributes.merge(owner: cropbot)) if photo.new_record?
    photo.save!
    association = photo.photo_associations.find_or_initialize_by(photographable: crop)
    association.update!(label: params[:kind].presence_in(PhotoAssociation::CROP_KINDS))
    redirect_to crop_path(crop), notice: t('.added', crop: crop.name)
  rescue FlickrPublicPhoto::Rejected => e
    redirect_to crop_path(crop), alert: t("crop_photos.create.#{e.reason}")
  rescue ActiveRecord::RecordInvalid
    redirect_to crop_path(crop), alert: t('.unavailable')
  end

  private

  def cropbot
    Member.find_by!(login_name: 'cropbot')
  end
end
