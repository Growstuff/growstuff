class PlantingsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  after_action :expire_homepage, only: %i(create update destroy)
  after_action :update_crop_medians, only: %i(create update destroy)
  after_action :update_planting_medians, only: :update
  load_and_authorize_resource

  respond_to :html, :json
  respond_to :csv, :rss, only: [:index]
  responders :flash

  def index
    @owner = Member.find_by(slug: params[:member_slug]) if params[:member_slug]
    @crop = Crop.find_by(slug: params[:crop_slug]) if params[:crop_slug]

    @show_all = params[:all] == '1'

    @plantings = @plantings.where(owner: @owner) if @owner.present?
    @plantings = @plantings.where(crop: @crop) if @crop.present?

    @plantings = @plantings.active unless params[:all] == '1'

    @plantings = @plantings.joins(:owner, :crop, :garden)
      .order(created_at: :desc)
      .includes(:owner, :garden, crop: :parent)
      .paginate(page: params[:page])

    @filename = "Growstuff-#{specifics}Plantings-#{Time.zone.now.to_s(:number)}.csv"

    respond_with(@plantings)
  end

  def show
    @photos = @planting.photos.includes(:owner).order(date_taken: :desc)
    @matching_seeds = matching_seeds
    @neighbours = @planting.nearby_same_crop
      .where.not(id: @planting.id)
      .limit(6)
    respond_with @planting
  end

  def new
    @planting = Planting.new(
      planted_at: Time.zone.today,
      owner:      current_member,
      garden:     current_member.gardens.first
    )
    @seed = Seed.find_by(slug: params[:seed_id]) if params[:seed_id]
    @crop = Crop.approved.find_by(id: params[:crop_id]) || Crop.new
    if params[:garden_id]
      @planting.garden = Garden.find_by(
        owner: current_member,
        id:    params[:garden_id]
      )
    end

    respond_with @planting
  end

  def edit
    # the following are needed to display the form but aren't used
    @crop = Crop.new
    @gardens = @planting.owner.gardens.active.order_by_name
  end

  def create
    @planting = Planting.new(planting_params)
    @planting.planted_at = Time.zone.now if @planting.planted_at.blank?
    @planting.owner = current_member
    @planting.crop = @planting.parent_seed.crop if @planting.parent_seed.present?
    @planting.save
    respond_with @planting
  end

  def update
    @planting.update(planting_params)
    respond_with @planting
  end

  def destroy
    @planting.destroy
    respond_with @planting, location: @planting.garden
  end

  private

  def update_crop_medians
    @planting.crop.update_lifespan_medians if @planting.crop.present?
  end

  def update_planting_medians
    @planting.update_harvest_days!
  end

  def planting_params
    params[:planted_at] = parse_date(params[:planted_at]) if params[:planted_at]
    params.require(:planting).permit(
      :crop_id, :description, :garden_id, :planted_at,
      :parent_seed_id,
      :quantity, :sunniness, :planted_from, :finished,
      :finished_at
    )
  end

  def plantings
    p = if @owner
          @owner.plantings
        elsif @crop
          @crop.plantings
        else
          Planting
        end
    p = p.current unless @show_all
    p.joins(:owner, :crop, :garden)
      .order(created_at: :desc)
      .includes(:crop, :owner, :garden)
      .paginate(page: params[:page])
  end

  def matching_seeds
    Seed.where(crop: @planting.crop, owner: @planting.owner)
      .where('(finished_at IS NULL OR finished_at >= ?)', @planting.planted_at)
      .where('(saved_at IS NULL OR saved_at <= ?)', @planting.planted_at)
  end

  def specifics
    if @owner.present?
      "#{@owner.to_param}-"
    elsif @crop.present?
      "#{@crop.to_param}-"
    end
  end
end
