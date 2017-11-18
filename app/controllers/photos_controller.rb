class PhotosController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  after_action :expire_homepage, only: [:create, :delete]
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
    @photos = @photos.includes(:owner).order(:created_at).paginate(page: params[:page])
    respond_with(@photos)
  end

  def new
    @id = params[:id]
    @type = params[:type]
    redirect_to photos_path if @type.nil?

    @photo = Photo.new
    @item = item_to_link_to
    retrieve_from_flickr
    respond_with @photo
  end

  def edit
    respond_with @photo
  end

  def create
    @photo = find_or_create_photo_from_flickr_photo
    @item = item_to_link_to
    raise "Could not find this item owned by you" unless @item
    collection << @item unless collection.include?(@item)
    @photo.save! if @photo.present?
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

  def item_id?
    item_id.present?
  end

  def item_id
    params.key? :id
  end

  def flickr_photo_id_param
    params[:photo][:flickr_photo_id]
  end

  def photo_params
    params.require(:photo).permit(:flickr_photo_id, :title, :license_name,
      :license_url, :thumbnail_url, :fullsize_url, :link_url)
  end

  def find_or_create_photo_from_flickr_photo
    photo = Photo.find_by(flickr_photo_id: flickr_photo_id_param)
    photo ||= Photo.new(photo_params)
    photo.owner_id = current_member.id
    photo.set_flickr_metadata
    photo
  end

  def collection
    raise "Missing or invalid type provided" unless Growstuff::Constants::PhotoModels.types.include?(params[:type])
    raise "No item id provided" unless item_id?
    Growstuff::Constants::PhotoModels.get_relation(@photo, params[:type])
  end

  def item_to_link_to
    item_class = Growstuff::Constants::PhotoModels.get_item(params[:type])
    item_class.find_by!(id: params[:id], owner_id: current_member.id)
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
