class Api::V1::PhotosController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /photos
  # GET /photos.json
  api!
  param :page, :number
  def index
    @photos = Photo.paginate(page: params[:page])

    render json: @photos
  end

  # POST /photos.json
  api!
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

    if @photo.save
      render json: @photo, status: :created, location: @photo
    else
      render json: @photo.errors, status: :unprocessable_entity
    end
  end

  # PUT /photos/1.json
  api!
  def update
    @photo = Photo.find(params[:id])

    if @photo.update(photo_params)
      head :no_content
    else
      render json: @photo.errors, status: :unprocessable_entity
    end
  end

  # DELETE /photos/1.json
  api!
  def destroy
    @photo = Photo.find(params[:id])
    @photo.destroy
    
    format.json { head :no_content }
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
