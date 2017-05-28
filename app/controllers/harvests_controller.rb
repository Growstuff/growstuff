class HarvestsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :csv, only: :index
  responders :flash

  def index
    @owner = Member.find_by(slug: params[:owner])
    @crop = Crop.find_by(slug: params[:crop])
    @planting = Planting.find_by(slug: params['planting_id'])

    @harvests = harvests
    @filename = csv_filename
    respond_with(@harvests)
  end

  def show
    @matching_plantings = matching_plantings if @harvest.owner == current_member
    respond_with(@harvest)
  end

  def new
    @harvest = Harvest.new(harvested_at: Time.zone.today)
    @planting = Planting.find_by(slug: params[:planting_id]) if params[:planting_id]
    @crop = Crop.find_by(id: params[:crop_id])
    respond_with(@harvest)
  end

  def edit
    @planting = @harvest.planting if @harvest.planting_id
  end

  def create
    @harvest.crop_id = @harvest.planting.crop_id if @harvest.planting_id
    @harvest.save
    respond_with(@harvest)
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

  def harvests
    if @owner
      @owner.harvests
    elsif @crop
      @crop.harvests
    elsif @planting_id
      @planting.harvests
    else
      Harvest
    end.includes(:owner, :crop).paginate(page: params[:page])
  end

  def csv_filename
    specifics = if @owner
                  "#{@owner.login_name}-"
                elsif @crop
                  "#{@crop.name}-"
                end
    "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_s(:number)}.csv"
  end
end
