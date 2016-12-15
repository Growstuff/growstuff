class PhotosController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /photos
  # GET /photos.json
  def index
    @photos = Photo.paginate(page: params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @photos }
    end
  end

  # GET /photos/new
  # GET /photos/new.json
  def new
    @photo = Photo.new
    @type = params[:type]
    @id = params[:id]

    page = params[:page] || 1

    @flickr_auth = current_member.auth('flickr')
    @current_set = params[:set]
    if @flickr_auth
      @sets = current_member.flickr_sets
      photos, total = current_member.flickr_photos(page, @current_set)

      @photos = WillPaginate::Collection.create(page, 30, total) do |pager|
        pager.replace photos
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @photo }
    end
  end

  # GET /photos/1/edit
  def edit
  end

  # POST /photos
  # POST /photos.json
  def create
    find_or_create_photo_from_flickr_photo
    add_photo_to_collection

    respond_to do |format|
      if @photo.present? && @photo.save
        format.html { redirect_to photo_path(@photo), notice: 'Photo was successfully added.' }
        format.json { render json: @photo, status: :created, location: @photo }
      else
        format.html { render action: "new" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /photos/1
  # PUT /photos/1.json
  def update
    respond_to do |format|
      if @photo.update(photo_params)
        format.html { redirect_to @photo, notice: 'Photo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo.destroy
    flash[:alert] = "Photo successfully deleted."

    respond_to do |format|
      format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end

  private

  def item_id?
    params.key? :id
  end

  def flickr_photo_id_param
    params[:photo][:flickr_photo_id]
  end

  def photo_params
    params.require(:photo).permit(:flickr_photo_id, :owner_id, :title, :license_name,
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
end
