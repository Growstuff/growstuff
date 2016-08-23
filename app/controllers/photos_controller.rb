class PhotosController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
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
    @photo = Photo.find(params[:id])
  end

  # POST /photos
  # POST /photos.json
  def create
    @photo = Photo.find_by_flickr_photo_id(params[:photo][:flickr_photo_id]) ||
      Photo.new(photo_params)
    @photo.owner_id = current_member.id
    @photo.set_flickr_metadata


    collection = case params[:type]
                   when 'garden'
                     @photo.gardens
                   when 'planting'
                     @photo.plantings
                   when 'harvest'
                     @photo.harvests
                   else
                     nil
                 end

    if collection && has_item_id
      item = params[:type].camelcase.constantize.find_by_id(params[:id])
      if item && member_owns_item(item)
        collection << item unless collection.include?(item)
      else
        flash[:alert] = "Could not find this item owned by you"
      end
    else
      flash[:alert] = "Missing or invalid type or id parameter"
    end

    respond_to do |format|
      if @photo.save
        format.html { redirect_to @photo, notice: 'Photo was successfully added.' }
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
    @photo = Photo.find(params[:id])

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
    @photo = Photo.find(params[:id])
    @photo.destroy
    flash[:alert] = "Photo successfully deleted."
    
    respond_to do |format|
      format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end

  private

  def has_item_id
    params.key? :id
  end

  def member_owns_item(item)
    item.owner.id == current_member.id
  end

  def photo_params
    params.require(:photo).permit(:flickr_photo_id, :owner_id, :title, :license_name,
    :license_url, :thumbnail_url, :fullsize_url, :link_url)
  end
end
