# frozen_string_literal: true

class PhotosController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  before_action :set_crop_and_planting, only: :index
  after_action :expire_homepage, only: %i(create destroy)
  load_and_authorize_resource except: :create
  respond_to :html, :json
  responders :flash

  def index
    @photos = if @crop
                @crop.photos_with_varieties
              elsif @planting
                @planting.photos
              else
                Photo.all
              end

    @photos = @photos.includes(:owner)
      .order(@crop ? { likes_count: :desc, created_at: :desc } : { created_at: :desc })
      .paginate(page: params[:page], per_page: Photo.per_page)

    raise ActiveRecord::RecordNotFound if @photos.out_of_bounds?

    respond_with(@photos)
  end

  def show
    respond_with(@photo)
  end

  def new
    @photo = Photo.new
    @item = item_to_link_to
    @type = params[:type]
    @id = params[:id]
    @label = params[:label]
    @mastodon_auths = current_member.authentications.where(provider: 'mastodon').order(:id)
    @sources = []
    @sources << 'flickr' if current_member.auth('flickr').present?
    @sources << 'mastodon' if @mastodon_auths.any?
    # With no account connected, offer both connection paths instead of an empty picker.
    @sources = %w(flickr mastodon) if @sources.empty?
    @source = @sources.include?(params[:source]) ? params[:source] : @sources.first
    if @source == 'mastodon'
      authorize! :update, @item
      @picker = mastodon_picker_json.merge(picker_options)
      return render json: @picker if request.format.json?

      return render :new
    end
    retrieve_from_flickr
    return render json: flickr_picker_json.merge(picker_options) if request.format.json?

    respond_with @photo
  end

  def edit
    respond_with @photo
  end

  def create
    # Import options (status_id and license_accepted) are not Photo attributes.
    # Authorize here instead of letting CanCan mass-assign the incoming params.
    authorize! :create, Photo
    ActiveRecord::Base.transaction do
      @item = item_to_link_to
      raise "Could not find this #{type} owned by you" unless @item

      @photo = if params.dig(:photo, :source) == 'mastodon'
                 authorize! :update, @item
                 mastodon_source.import(status_id: params.dig(:photo, :status_id), attachment_id: params.dig(:photo, :source_id),
                                        license_accepted: params.dig(:photo, :license_accepted))
               else
                 find_or_create_photo_from_flickr_photo
               end
      @photo.save! if @photo.present?
      link_photo_to_item
    end
    return render_added_json if request.format.json?

    respond_with @photo
  rescue ActiveRecord::RecordInvalid => e
    raise unless request.format.json?

    render json: { errors: e.record.errors }, status: :unprocessable_content
  rescue MastodonPhotoSource::Rejected => e
    if request.format.json?
      render json: { errors: { base: [t("photos.import_picker.#{e.reason}")] } }, status: :unprocessable_content
    else
      redirect_to new_photo_path(type: params[:type], id: params[:id], label: params[:label], source: 'mastodon',
                                 authentication_id: params[:authentication_id]), alert: t("photos.import_picker.#{e.reason}")
    end
  end

  def update
    @photo.update(update_params)
    respond_with @photo
  end

  # Reads the photo again from Flickr: see Photo#refresh_from_flickr!.
  def refresh
    @photo.refresh_from_flickr!
    redirect_to @photo, notice: t('.refreshed')
  rescue FlickrPublicPhoto::Rejected => e
    redirect_to @photo, alert: t(".#{e.reason}")
  rescue ActiveRecord::RecordInvalid
    redirect_to @photo, alert: t('.unavailable')
  end

  def destroy
    @photo.destroy
    respond_with @photo
  end

  private

  def picker_options
    { source: @source, sources: @sources, accounts: @mastodon_auths.map { |auth| { id: auth.id, name: auth.name } },
      labels: t('photos.import_picker'), connect_mastodon_url: "#{edit_member_registration_path}#apps" }
  end

  def mastodon_authentication
    auths = current_member.authentications.where(provider: 'mastodon').order(:id)
    params[:authentication_id].present? ? auths.find(params[:authentication_id]) : auths.first
  end

  def mastodon_source
    auth = mastodon_authentication
    raise MastodonPhotoSource::Rejected, :invalid_photo unless auth

    MastodonPhotoSource.new(auth)
  end

  def mastodon_picker_json
    auth = mastodon_authentication
    return { state: 'connect', source: 'mastodon' } unless auth

    { state: 'ready', source: 'mastodon', authentication_id: auth.id, name: auth.name, sets: [],
      **MastodonPhotoSource.new(auth).photos(cursor: params[:cursor], tag: params[:tag]) }
  rescue MastodonPhotoSource::Rejected => e
    { state: 'unavailable', source: 'mastodon', error: t("photos.import_picker.#{e.reason}") }
  end

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
      photos: @photos.map do |photo|
        { id: photo.id, title: photo.title, thumb_url: FlickRaw.url_n(photo), preview_url: FlickRaw.url_z(photo) }
      end
    }
  end

  # The garden's refreshed card too, when the photo went on a garden or one of
  # its plantings, as a garden's picture may now be this one.
  def render_added_json
    garden = @item.is_a?(Garden) ? @item : (@item.garden if @item.respond_to?(:garden))
    card = GardenCardSerializer.collection([garden], ability: current_ability, show_owner: false).first if garden
    photo = { id: @photo.id, url: photo_path(@photo), title: @photo.title,
              thumbnail_url: @photo.thumbnail_url, fullsize_url: @photo.fullsize_url }
    render json: { photo:, garden: card }, status: :created
  end

  # The title is ours to change; the rest is the photo as Flickr describes it.
  def update_params
    params.require(:photo).permit(:title)
  end

  def photo_params
    params.require(:photo).permit(:source_id, :source, :title, :license_name,
                                  :license_url, :thumbnail_url, :fullsize_url, :link_url, :date_taken)
  end

  # Attaches the photo to the item. A photo can say what part of the item it is
  # of, as `label`: before or after for a job, front or back for a seed packet.
  def link_photo_to_item
    association = @item.photo_associations.find_or_initialize_by(photo: @photo)
    association.label = params[:label] if params[:label].present?
    association.save!
  end

  # Item with photos attached
  def item_to_link_to
    raise "No item id provided" if params[:id].nil?
    raise "No item type provided" if params[:type].nil?

    item_class = params[:type].capitalize
    raise "Photos not supported" unless Photo::PHOTO_CAPABLE.include? item_class

    klass = item_class.constantize
    # A draft post is still its author's to add photos to.
    klass = klass.with_drafts if klass.respond_to?(:with_drafts)
    klass.find(params[:id])
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
