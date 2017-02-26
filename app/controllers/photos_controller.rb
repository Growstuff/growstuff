class PhotosController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource
  respond_to :html, :json

  # GET /photos
  # GET /photos.json
  def index
    @photos = Photo.paginate(page: params[:page])
    respond_with(@photos)
  end

  # GET /photos/new
  # GET /photos/new.json
  def new
    @type = params[:type]
    @id = params[:id]

    @photo = Photo.new
    retrieve_from_flickr
    respond_with(@photo)
  end

  # GET /photos/1/edit
  def edit
  end

  # POST /photos
  # POST /photos.json
  def create
    find_or_create_photo_from_flickr_photo
    add_photo_to_collection
    flash[:notice] = 'Photo was successfully added.' if @photo.present? && @photo.save
    respond_with(@photo)
  end

  # PUT /photos/1
  # PUT /photos/1.json
  def update
    flash[:notice] = 'Photo was successfully updated.' if @photo.update(photo_params)
    respond_with(@photo)
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo.destroy
    flash[:alert] = "Photo successfully deleted."
    respond_with(@photo)
  end

  private

  def item_id?
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
    @photo = Photo.find_by(flickr_photo_id: flickr_photo_id_param)
    @photo = Photo.new(photo_params) unless @photo
    @photo.owner_id = current_member.id
    @photo.set_flickr_metadata
    @photo
  end

  def add_photo_to_collection
    raise "Missing or invalid type provided" unless Growstuff::Constants::PhotoModels.types.include?(params[:type])
    raise "No item id provided" unless item_id?
    collection = Growstuff::Constants::PhotoModels.get_relation(@photo, params[:type])

    item_class = Growstuff::Constants::PhotoModels.get_item(params[:type])
    item = item_class.find_by!(id: params[:id], owner_id: current_member.id)
    raise "Could not find this item owned by you" unless item

    collection << item unless collection.include?(item)
  rescue => e
    flash[:alert] = e.message
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
