# frozen_string_literal: true

class HarvestsController < DataController
  after_action :update_crop_medians, only: %i(create update destroy)

  def index
    where = {}
    if params[:member_slug]
      @owner = Member.find_by(slug: params[:member_slug])
      where['owner_id'] = @owner.id
    end

    if params[:crop_slug]
      @crop = Crop.find_by(slug: params[:crop_slug])
      where['crop_id'] = @crop.id
    end

    if params[:planting_slug]
      @planting = Planting.find_by(slug: params[:planting_slug])
      where['planting_id'] = @planting.id
    end

    @harvests = Harvest.search('*', where:    where,
                                    limit:    100,
                                    page:     params[:page],
                                    load:     false,
                                    boost_by: [:created_at])

    @filename = csv_filename

    respond_with(@harvests)
  end

  def show
    @matching_plantings = matching_plantings if @harvest.owner == current_member
    @photos = @harvest.photos.order(created_at: :desc).paginate(page: params[:page])
    respond_with(@harvest)
  end

  def new
    @harvest = Harvest.new(harvested_at: Time.zone.today)
    @planting = Planting.find_by(slug: params[:planting_slug]) if params[:planting_slug]
    @crop = Crop.find_by(id: params[:crop_id])
    respond_with(@harvest)
  end

  def edit
    @planting = @harvest.planting if @harvest.planting_id
    respond_with(@harvest)
  end

  def create
    @harvest.crop_id = @harvest.planting.crop_id if @harvest.planting_id
    @harvest.harvested_at = Time.zone.now if @harvest.harvested_at.blank?
    @harvest.save
    if params[:return] == 'planting'
      respond_with(@harvest, location: @harvest.planting)
    else
      respond_with(@harvest)
    end
  end

  def update
    @harvest.update(harvest_params)
    respond_with(@harvest)
  end

  def destroy
    @harvest.destroy
    respond_with(@harvest)
  end

  private

  def harvest_params
    params.require(:harvest)
      .permit(:planting_id, :crop_id, :harvested_at, :description,
              :quantity, :unit, :weight_quantity, :weight_unit,
              :plant_part_id, :slug, :si_weight)
      .merge(owner_id: current_member.id)
  end

  def matching_plantings
    Planting.where(crop: @harvest.crop, owner: @harvest.owner)
      .where('(planted_at IS NULL OR planted_at <= ?)', @harvest.harvested_at)
      .where('(finished_at IS NULL OR finished_at >= ?)', @harvest.harvested_at)
  end

  def csv_filename
    specifics = if @owner
                  "#{@owner.to_param}-"
                elsif @crop
                  "#{@crop.to_param}-"
                end
    "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_s(:number)}.csv"
  end

  def update_crop_medians
    # We only update medians to predict plantings
    # if this harvest is not linked to a planting, then do nothing
    return if @harvest.planting.nil?

    @harvest.planting.update_harvest_days!
    @harvest.crop.update_harvest_medians
  end
end
