# frozen_string_literal: true

class PhotosController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  before_action :set_crop_and_planting, only: :index
  after_action :expire_homepage, only: %i(create destroy)
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def show
    @crops = Crop.distinct.joins(:photo_associations).where(photo_associations: { photo: @photo })
    respond_with(@photo)
  end

  def index
    @photos = Photo.search(
      load:     false,
      boost_by: [:created_at],
      where:    index_where_clause,
      page:     params[:page],
      limit:    Photo.per_page
    )
    respond_with(@photos)
  end

  def new
    @photo = Photo.new
    @item = item_to_link_to
    @type = params[:type]
    @id = params[:id]
    retrieve_from_flickr
    respond_with @photo
  end

  def edit
    respond_with @photo
  end

  def create
    ActiveRecord::Base.transaction do
      @photo = find_or_create_photo_from_flickr_photo
      @item = item_to_link_to
      raise "Could not find this #{type} owned by you" unless @item

      @item.photos << @photo unless @item.photos.include? @photo
      @photo.save! if @photo.present?
    end
    respond_with @photo
  end

  def update
    @photo.update(photo_params)
    respond_with @photo
  end

  def destroy
    @photo.destroy
    respond_with @photo
  end

  private

  def photo_params
    params.require(:photo).permit(:source_id, :source, :title, :license_name,
                                  :license_url, :thumbnail_url, :fullsize_url, :link_url)
  end

  # Item with photos attached
  def item_to_link_to
    raise "No item id provided" if params[:id].nil?
    raise "No item type provided" if params[:type].nil?

    item_class = params[:type].capitalize
    raise "Photos not supported" unless Photo::PHOTO_CAPABLE.include? item_class

    item_class.constantize.find(params[:id])
  end

  #
  # Flickr retrieval
  def find_or_create_photo_from_flickr_photo
    photo = Photo.find_or_initialize_by(
      source_id: photo_params[:source_id],
      source:    'flickr'
    )
    photo.update(photo_params)
    photo.owner_id = current_member.id
    photo.set_flickr_metadata!
    photo
  end

  def retrieve_from_flickr
    @flickr_auth = current_member.auth('flickr')
    return if @flickr_auth.nil?

    unless current_member.flickr_auth_valid?
      current_member.remove_stale_flickr_auth
      @please_reconnect_flickr = true
      return
    end

    @current_set = params[:set]

    page = params[:page] || 1

    @sets = current_member.flickr_sets
    photos, total = current_member.flickr_photos(page, @current_set)

    @photos = WillPaginate::Collection.create(page, 30, total) do |pager|
      pager.replace photos
    end
  end

  def index_where_clause
    if params[:crop_slug]
      { crops: @crop.id }
    elsif params[:planting_id]
      { planting_id: @planting.id }
    else
      {}
    end
  end

  def set_crop_and_planting
    @crop = Crop.find params[:crop_slug] if params[:crop_slug]
    @planting = Planting.find params[:planting_id] if params[:planting_id]
  end
end
