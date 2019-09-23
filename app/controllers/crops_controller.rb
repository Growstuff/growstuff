require 'will_paginate/array'

class CropsController < ApplicationController
  before_action :authenticate_member!, except: %i(index hierarchy search show)
  load_and_authorize_resource
  skip_authorize_resource only: %i(hierarchy search)
  respond_to :html, :json, :rss, :csv, :svg
  responders :flash

  def index
    @sort = params[:sort]
    @crops = crops
    @num_requested_crops = requested_crops.size if current_member
    @filename = filename
    respond_with @crops
  end

  def requested
    @requested = requested_crops.paginate(page: params[:page])
    respond_with @requested
  end

  def wrangle
    @approval_status = params[:approval_status]
    @crops = case @approval_status
             when "pending"
               Crop.pending_approval
             when "rejected"
               Crop.rejected
             else
               Crop.recent
             end.paginate(page: params[:page])

    @crop_wranglers = Role.crop_wranglers
    respond_with @crops
  end

  def openfarm
    @crop = Crop.find(params[:crop_slug])
    @crop.update_openfarm_data!
    respond_with @crop, location: @crop
  end

  def hierarchy
    @crops = Crop.toplevel.order(:name)
    respond_with @crops
  end

  def search
    @term = params[:term]

    @crops = CropSearchService.search(
      @term, page:           params[:page],
             per_page:       12,
             current_member: current_member
    )
    respond_with @crops
  end

  def show
    @crop = Crop.includes(:scientific_names, plantings: :photos)
      .find_by!(slug: params[:slug])
    @posts = @crop.posts.order(created_at: :desc).paginate(page: params[:page])

    @photos = Photo.by_crop(@crop)

    respond_to do |format|
      format.html
      format.svg { send_data(@crop.svg_icon, type: "image/svg+xml", disposition: "inline") }
      format.json { render json: @crop.to_json(crop_json_fields) }
    end
  end

  def new
    @crop = Crop.new
    @crop.alternate_names.build
    @crop.scientific_names.build

    respond_with @crop
  end

  def edit
    @crop = Crop.find_by!(slug: params[:slug])
    @crop.alternate_names.build if @crop.alternate_names.blank?
    @crop.scientific_names.build if @crop.scientific_names.blank?
  end

  def create
    @crop = Crop.new(crop_params)

    if current_member.role? :crop_wrangler
      @crop.creator = current_member
    else
      @crop.requester = current_member
      @crop.approval_status = "pending"
    end

    notify_wranglers if Crop.transaction { @crop.save && save_crop_names }

    respond_with @crop
  end

  def update
    @crop = Crop.find_by!(slug: params[:slug])

    if params.fetch("reject", false) && can?(:wrangle, @crop)
      @crop.approval_status = 'rejected'
    elsif params.fetch("approve", false) && can?(:wrangle, @crop)
      @crop.approval_status = 'approved'
    end

    @crop.creator = current_member if @crop.approval_status == "pending"
    if @crop.update(crop_params)
      recreate_names('alt_name', 'alternate')
      recreate_names('sci_name', 'scientific')

      notifier.deliver_now! if @crop.approval_status_changed?(from: "pending", to: "approved")
    else
      @crop.approval_status = @crop.approval_status_was
    end

    respond_with @crop
  end

  def destroy
    @crop = Crop.find_by!(slug: params[:slug])
    authorize! :destroy, @crop
    @crop.destroy
    respond_with @crop
  end

  private

  def notifier
    case @crop.approval_status
    when "approved"
      Notifier.crop_request_approved(@crop.requester, @crop)
    when "rejected"
      Notifier.crop_request_rejected(@crop.requester, @crop)
    end
  end

  def save_crop_names
    params[:alt_name]&.values&.each do |value|
      create_name!('alternate', value) unless value.empty?
    end
    params[:sci_name]&.values&.each do |value|
      create_name!('scientific', value) unless value.empty?
    end
  end

  def notify_wranglers
    return if current_member.role? :crop_wrangler

    Role.crop_wranglers&.each do |w|
      Notifier.new_crop_request(w, @crop).deliver_now!
    end
  end

  def recreate_names(param_name, name_type)
    return if params[param_name].blank?

    destroy_names(name_type)
    params[param_name].each do |_i, value|
      create_name!(name_type, value) unless value.empty?
    end
  end

  def destroy_names(name_type)
    @crop.send("#{name_type}_names").each(&:destroy)
  end

  def create_name!(name_type, value)
    @crop.send("#{name_type}_names").create!(name: value, creator_id: current_member.id)
  end

  def crop_params
    params.require(:crop).permit(
      :en_wikipedia_url,
      :name,
      :parent_id,
      :perennial,
      :request_notes,
      :reason_for_rejection,
      :rejection_notes,
      scientific_names_attributes: %i(scientific_name
                                      _destroy
                                      id))
  end

  def filename
    "Growstuff-Crops-#{Time.zone.now.to_s(:number)}.csv"
  end

  def crop_json_fields
    {
      include: {
        plantings:        {
          include: {
            owner: { only: %i(id login_name location latitude longitude) }
          }
        },
        scientific_names: { only: [:name] },
        alternate_names:  { only: [:name] }
      }
    }
  end

  def crops
    q = Crop.approved.includes(:scientific_names, plantings: :photos)
    q = q.popular unless @sort == 'alpha'
    q.order(Arel.sql("LOWER(crops.name)"))
      .includes(:photos).paginate(page: params[:page])
  end

  def requested_crops
    current_member.requested_crops.pending_approval
  end
end
