class PhotosController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  after_action :expire_homepage, only: %i(create delete)
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def index
    if params[:crop_id]
      @crop = Crop.find params[:crop_id]
      @photos = @crop.photos
    else
      @photos = Photo.all
    end
    @photos = @photos.order(created_at: :desc)
      .includes(:owner)
      .paginate(page: params[:page])
    respond_with(@photos)
  end

  def new
    @photo = Photo.new
    @item = item_to_link_to
    @type = item_type
    @id = item_id
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

  #
  # Params
  def item_id
    params[:id]
  end

  def item_type
    params[:type]
  end

  def flickr_photo_id_param
    params[:photo][:flickr_photo_id]
  end

  def photo_params
    params.require(:photo).permit(:flickr_photo_id, :title, :license_name,
      :license_url, :thumbnail_url, :fullsize_url, :link_url)
  end

  # Item with photos attached
  def item_to_link_to
    raise "No item id provided" if item_id.nil?
    raise "No item type provided" if item_type.nil?
    item_class = item_type.capitalize
    raise "Photos not supported" unless Photo::PHOTO_CAPABLE.include? item_class
    item_class.constantize.find_by!(id: params[:id], owner_id: current_member.id)
  end

  #
  # Flickr retrieval
  def find_or_create_photo_from_flickr_photo
    photo = Photo.find_by(flickr_photo_id: flickr_photo_id_param)
    photo ||= Photo.new(photo_params)
    photo.owner_id = current_member.id
    photo.set_flickr_metadata!
    photo
  end

  def retrieve_from_flickr
    @flickr_auth = current_member.auth('flickr')
    @current_set = params[:set]
    return unless @flickr_auth

    page = params[:page] || 1

    @sets = current_member.flickr_sets
    photos, total = current_member.flickr_photos(page, @current_set)

    @photos = WillPaginate::Collection.create(page, 30, total) do |pager|
      pager.replace photos
    end
  end
end
