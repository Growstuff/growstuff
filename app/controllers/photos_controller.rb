class PhotosController < ApplicationController
  before_filter :authenticate_member!, :except => [:index, :show]
  load_and_authorize_resource

  # GET /photos
  # GET /photos.json
  def index
    @photos = Photo.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @photos }
    end
  end

  # GET /photos/1
  # GET /photos/1.json
  def show
    @photo = Photo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @photo }
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

    # several models can have photos. we need to know what model and the id
    # for the entry to attach the photo to
    valid_models = ["planting", "harvest", "garden"]
    if params[:type]
      if valid_models.include?(params[:type])
        if params[:id]
          item = params[:type].camelcase.constantize.find_by_id(params[:id])
          if item
            if item.owner.id == current_member.id
              #  This syntax is weird, so just know that it means this:
              #  @photo.harvests << item unless @photo.harvests.include?(item)
              #  but with the correct many-to-many relationship automatically referenced
              (@photo.send "#{params[:type]}s") << item unless (@photo.send "#{params[:type]}s").include?(item)
            else
              flash[:alert] = "You must own both the #{params[:type]} and the photo."
            end
          else
            flash[:alert] = "Couldn't find #{params[:type]} to connect to photo."
          end
        else
          flash[:alert] = "Missing id parameter"
        end
      else
        flash[:alert] = "Cannot attach photos to #{params[:type]}"
      end
    else    
      flash[:alert] = "Missing type parameter"
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

  def photo_params
    params.require(:photo).permit(:flickr_photo_id, :owner_id, :title, :license_name,
    :license_url, :thumbnail_url, :fullsize_url, :link_url)
  end
end
