# frozen_string_literal: true

require 'will_paginate/array'

class CropsController < ApplicationController
  before_action :authenticate_member!, except: %i(index hierarchy search show)
  load_and_authorize_resource id_param: :slug
  skip_authorize_resource only: %i(hierarchy search)
  respond_to :html, :json, :rss, :csv, :svg
  responders :flash

  def index
    @crops = Crop.search_by_name(nil).paginate(page: params[:page], per_page: 100)
    if request.format.csv? || request.format.rss?
      @crops = @crops.includes(:parent, :scientific_names, :seeds, :harvests, :creator, :plantings)
    end
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
    @all_levels = params[:level] == 'all'
    @query = params[:q].to_s.squish
    @crops = wrangle_crops.paginate(page: params[:page])

    @crop_wranglers = Role.crop_wranglers
    respond_with @crops
  end

  def gbif
    @crop = Crop.find(params[:crop_slug])
    @crop.update_gbif_data!
    respond_with @crop, location: @crop
  end

  def hierarchy
    @crops = Crop.toplevel.order(:name)
    respond_with @crops
  end

  def search
    @term = params[:term]

    @crops = CropSearchService.search(@term,
                                      page:           params[:page],
                                      per_page:       Crop.per_page,
                                      current_member:)

    respond_to do |format|
      format.html do
        render
      end
      format.json do
        render json: @crops.map { |crop| crop_search_result(crop) }
      end
    end
  end

  def show
    respond_to do |format|
      format.html do
        @posts = @crop.posts.order(created_at: :desc).paginate(page: params[:page])
        @companions = @crop.companions.approved
        member_ids = @crop.versions.reorder(nil).distinct.pluck(:whodunnit).compact.map(&:to_i)
        @version_members = Member.where(id: member_ids).index_by(&:id)
      end
      format.svg do
        icon_data = @crop.svg_icon.presence || File.read(Rails.root.join("app/assets/images/icons/sprout.svg"))
        send_data(icon_data, type: "image/svg+xml", disposition: "inline")
      end
      format.json do
        render json: @crop.to_json(crop_json_fields)
      end
    end
  end

  def sowing_info
    render json: CropSowingInfoSerializer.new(@crop, member: current_member)
  end

  def new
    @crop = Crop.new
    @crop.alternate_names.build
    @crop.scientific_names.build

    respond_with @crop
  end

  def edit
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

    if Crop.transaction { @crop.save && save_crop_names }
      notify_wranglers
    else
      @crop.alternate_names.build
      @crop.scientific_names.build
    end

    respond_with @crop
  end

  def update
    if can?(:wrangle, @crop)
      @crop.approval_status = 'rejected' if params.fetch("reject", false)
      @crop.approval_status = 'approved' if params.fetch("approve", false)
    end

    @crop.creator = current_member if @crop.approval_status == "pending"

    if @crop.update(crop_params)
      recreate_names('alt_name', 'alternate')
      recreate_names('sci_name', 'scientific')

      notify_requester if @crop.approval_status_previously_changed?(from: "pending")
      @crop.update_gbif_data! if @crop.approval_status_previously_changed?(from: "pending", to: "approved")
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

  def data_improvement
    @active_tab = params[:tab] || 'photos'

    @crops = case @active_tab
             when 'photos'
               Crop.approved.where(photo_associations_count: 0).order(plantings_count: :desc)
             when 'descriptions'
               Crop.approved.where(description: [nil, '']).order(plantings_count: :desc)
             when 'youtube'
               Crop.approved.where(en_youtube_url: [nil, '']).order(plantings_count: :desc)
             when 'alternate_names'
               Crop.approved.where.missing(:alternate_names).order(plantings_count: :desc)
             when 'wikidata'
               crops_with_wikidata = Crop.joins(:scientific_names).where.not(scientific_names: { wikidata_id: nil }).distinct
               Crop.approved.where.not(id: crops_with_wikidata).order(plantings_count: :desc)
             when 'row_spacing'
               Crop.approved.where(row_spacing: nil).order(plantings_count: :desc)
             when 'sun_requirements'
               Crop.approved.where(sun_requirements: [nil, '']).order(plantings_count: :desc)
             when 'height'
               Crop.approved.where(height: nil).order(plantings_count: :desc)
             when 'public_food_key'
               Crop.approved.where(public_food_key: [nil, '']).order(plantings_count: :desc)
             else
               Crop.none
             end.paginate(page: params[:page], per_page: 50)
  end

  # A search hit, plus the alternate name that matched the term when the
  # crop's own name didn't ("aubergine" finds eggplant)
  def crop_search_result(crop)
    result = crop.as_json(only: %i(id name slug))
    return result if word_start_match?(crop.name, @term)

    matched = crop.alternate_names.map(&:name).find { |name| word_start_match?(name, @term) }
    result['matched_alternate_name'] = matched if matched
    result
  end

  def word_start_match?(name, term)
    name = name.to_s.downcase
    term = term.to_s.downcase.strip
    name.start_with?(term) || name.split(/[\s-]+/).any? { |word| word.start_with?(term) }
  end

  private

  # The crops on the wrangling page: the tab's, then either the ones matching a
  # search, from every level and best match first, or the top level ones unless
  # all are asked for. By name otherwise.
  def wrangle_crops
    crops = case @approval_status
            when "pending" then Crop.pending_approval
            when "rejected" then Crop.rejected
            else Crop.approved
            end

    if @query.present?
      crops = crops.matching_name(@query).best_match_first(@query)
    elsif !@all_levels
      crops = crops.where(parent_id: nil)
    end

    crops.includes(:scientific_names, :alternate_names, :varieties, :crop_job_templates, :creator, :requester)
      .order(Arel.sql('lower(crops.name)'), :id)
  end

  def notify_requester
    return unless @crop.requester

    case @crop.approval_status
    when "approved"
      NotifierMailer.crop_request_approved(@crop.requester, @crop).deliver_now!
    when "rejected"
      NotifierMailer.crop_request_rejected(@crop.requester, @crop).deliver_now!
    end
  end

  def save_crop_names
    AlternateName.create!(names_params(:alt_name).map { |n| { name: n, creator_id: current_member.id, crop_id: @crop.id, language: "EN" } })
    ScientificName.create!(names_params(:sci_name).map { |n| { name: n, creator_id: current_member.id, crop_id: @crop.id } })
  end

  def notify_wranglers
    return if current_member.role? :crop_wrangler

    Role.crop_wranglers&.each do |w|
      NotifierMailer.new_crop_request(w, @crop).deliver_now!
    end
  end

  def recreate_names(param_name, name_type)
    return if params[param_name].blank?

    @crop.send("#{name_type}_names").each(&:destroy)
    params[param_name].each_value do |value|
      next if value.empty?

      if name_type == 'alternate'
        @crop.send("#{name_type}_names").create!(name: value, creator_id: current_member.id, language: "EN")
      else
        @crop.send("#{name_type}_names").create!(name: value, creator_id: current_member.id)
      end
    end
  end

  def crop_params
    params.require(:crop).permit(
      :name, :en_wikipedia_url, :en_youtube_url,
      :parent_id, :perennial, :icon,
      :request_notes, :reason_for_rejection,
      :rejection_notes,
      :description,
      :public_food_key,
      :row_spacing, :spread, :height,
      :sowing_method, :sun_requirements, :growing_degree_days,
      scientific_names_attributes: %i(scientific_name _destroy id)
    )
  end

  def names_params(name_type)
    params.require(name_type).values&.reject { |n| n.empty? }
  end

  def filename
    "Growstuff-Crops-#{Time.zone.now.to_fs(:number)}.csv"
  end

  def crop_json_fields
    {
      include: {
        plantings: {
          include: {
            owner: { only: %i(id login_name location latitude longitude) }
          }
        },
        scientific_names: { only: [:name] }, alternate_names:  { only: %i(name language) }
      }
    }
  end

  def requested_crops
    current_member.requested_crops.pending_approval
  end
end
