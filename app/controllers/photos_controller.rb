class PhotosController < ApplicationController
  load_and_authorize_resource
  # GET /photos
  # GET /photos.json
  def index
    @photos = Photo.all

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

  # I really hate the mixture of side-effects and return values here.
  # It's done like this for easier mocking. Hopefully it'll soon be deleted!
  def login_to_flickr()
    FlickRaw.api_key = ENV['FLICKR_KEY']
    FlickRaw.shared_secret = ENV['FLICKR_SECRET']
    flickr = FlickRaw::Flickr.new
    flickr.access_token = @flickr_auth.token
    flickr.access_secret = @flickr_auth.secret
    @flickr_login = flickr.test.login
    return flickr
  end

  def get_photos(flickr)
    @photos = flickr.people.getPhotos(:user_id => 'me', :per_page => 30)
  end

  # GET /photos/new
  # GET /photos/new.json
  def new
    @photo = Photo.new

    # NOTE: we should move a bunch of this into the Member model
    @flickr_login = nil
    @flickr_auth = current_member.auth('flickr')

    if @flickr_auth
      flickr = login_to_flickr()
      get_photos(flickr)
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
    @photo = Photo.new(params[:photo])

    respond_to do |format|
      if @photo.save
        format.html { redirect_to @photo, notice: 'Photo was successfully created.' }
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
      if @photo.update_attributes(params[:photo])
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

    respond_to do |format|
      format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end
end
