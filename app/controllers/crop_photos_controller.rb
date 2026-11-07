# frozen_string_literal: true

# Lets a crop wrangler find photos of a crop on Flickr and add one, saying what it shows.
# The photo needs no planting, seed or harvest: see AddCropPhoto.
class CropPhotosController < ApplicationController
  before_action :authenticate_member!

  # Photos on Flickr that might suit the crop, for the wrangler to pick from.
  def new
    @crop = Crop.find(params[:crop_slug])
    authorize! :edit, @crop
    @query = params[:q].presence || @crop.name
    @results = FlickrPublicPhoto.search(@query, page: params[:page].to_i.clamp(1, 100))
  rescue FlickrPublicPhoto::Rejected
    redirect_to crop_path(@crop), alert: t('crop_photos.create.unavailable')
  end

  def create
    crop = Crop.find(params[:crop_slug])
    authorize! :edit, crop

    kind = params[:kind].presence_in(PhotoAssociation::CROP_KINDS)
    return redirect_to(crop_path(crop), alert: t('.kind_missing')) unless kind

    photo = AddCropPhoto.new(crop, url: params[:url], kind: kind).call
    redirect_to photo_path(photo), notice: t('.added', crop: crop.name)
  rescue FlickrPublicPhoto::Rejected => e
    redirect_to crop_path(crop), alert: t(".#{e.reason}")
  rescue ActiveRecord::RecordInvalid
    redirect_to crop_path(crop), alert: t('.unavailable')
  end
end
