# frozen_string_literal: true

class PhotosController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  before_action :set_crop_and_planting, only: :index
  after_action :expire_homepage, only: %i(create destroy)
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def index
    @photos = if @crop
                @crop.photos
              elsif @planting
                @planting.photos
              else
                Photo.all
              end

    @photos = @photos.includes(:owner)
                     .order(created_at: :desc)
                     .paginate(page: params[:page], per_page: Photo.per_page)

    raise ActiveRecord::RecordNotFound if @photos.out_of_bounds?

    respond_with(@photos)
  end

  def show
    @crops = Crop.distinct.joins(:photo_associations).where(photo_associations: { photo: @photo })
    @comment = Comment.new(commentable: @photo)
    respond_with(@photo)
  end

  def new
    @photo = Photo.new
    @item = item_to_link_to
    @type = params[:type]
    @id = params[:id]
    retrieve_from_flickr
    return render json: flickr_picker_json if request.format.json?

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
    return render_added_json if request.format.json?

    respond_with @photo
  rescue ActiveRecord::RecordInvalid => e
    raise unless request.format.json?

    render json: { errors: e.record.errors }, status: :unprocessable_content
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

  # For the React garden cards: what the "add photo" dialog needs to show, as
  # the page does. Not connected (or the connection has gone stale) sends you to
  # Flickr; otherwise a page of your photos, with your albums to choose from.
  def flickr_picker_json
    connect = { connect_url: '/members/auth/flickr' }
    return { state: 'connect', **connect } if @flickr_auth.nil?
    return { state: 'reconnect', **connect } if @please_reconnect_flickr

    {
      state: 'ready', name: @flickr_auth.name, profile_url: "http://flickr.com/photos/#{@flickr_auth.uid}",
      sets: (@sets || {}).map { |title, id| { id: id, title: title } },
      set: @current_set, tag: @current_tag,
      page: @photos.current_page, total_pages: @photos.total_pages, total: @photos.total_entries,
      photos: @photos.map { |photo| { id: photo.id, title: photo.title, thumb_url: FlickRaw.url_n(photo), preview_url: FlickRaw.url_z(photo) } }
    }
  end

  # The garden's refreshed card too, when the photo went on a garden or one of
  # its plantings, as a garden's picture may now be this one.
  def render_added_json
    garden = @item.is_a?(Garden) ? @item : (@item.garden if @item.respond_to?(:garden))
    card = GardenCardSerializer.collection([garden], ability: current_ability, show_owner: false).first if garden
    render json: { photo: { id: @photo.id, url: photo_path(@photo) }, garden: card }, status: :created
  end

  def photo_params
    params.require(:photo).permit(:source_id, :source, :title, :license_name,
                                  :license_url, :thumbnail_url, :fullsize_url, :link_url, :date_taken)
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
    @current_tag = params[:tag]

    page = params[:page] || 1

    @sets = current_member.flickr_sets
    photos, total = current_member.flickr_photos(page, @current_set, @current_tag)

    @photos = WillPaginate::Collection.create(page, 30, total) do |pager|
      pager.replace photos
    end
  end

  def set_crop_and_planting
    @crop = Crop.find params[:crop_slug] if params[:crop_slug]
    @planting = Planting.find params[:planting_id] if params[:planting_id]
    @planting ||= Planting.find params[:planting_slug] if params[:planting_slug]
  end
end
