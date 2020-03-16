# frozen_string_literal: true

class PlantingsController < DataController
  after_action :update_crop_medians, only: %i(create update destroy)
  after_action :update_planting_medians, only: :update

  def index
    @show_all = params[:all] == '1'

    where = {}
    where['active'] = true unless @show_all

    if params[:member_slug]
      @owner = Member.find_by(slug: params[:member_slug])
      where['owner_id'] = @owner.id
    end

    if params[:crop_slug]
      @crop = Crop.find_by(slug: params[:crop_slug])
      where['crop_id'] = @crop.id
    end

    @plantings = Planting.search(
      where:    where,
      page:     params[:page],
      limit:    30,
      boost_by: [:created_at],
      load:     false
    )

    @filename = "Growstuff-#{specifics}Plantings-#{Time.zone.now.to_s(:number)}.csv"

    respond_with(@plantings)
  end

  def show
    @photos = @planting.photos.includes(:owner).order(date_taken: :desc)
    @harvests = Harvest.search(where: { planting_id: @planting.id })
    @matching_seeds = matching_seeds
    @crop = @planting.crop

    # TODO: use elastic search long/lat
    @neighbours = @planting.nearby_same_crop
      .where.not(id: @planting.id)
      .includes(:owner, :crop, :garden)
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
