class HarvestsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :csv, only: :index

  # GET /harvests
  # GET /harvests.json
  def index
    @owner = Member.find_by(slug: params[:owner])
    @crop = Crop.find_by(slug: params[:crop])
    @harvests = harvests
    @filename = csv_filename
    respond_with(@harvests)
  end

  # GET /harvests/1
  # GET /harvests/1.json
  def show
    @matching_plantings = matching_plantings if @harvest.owner == current_member
    respond_with(@harvest)
  end

  # GET /harvests/new
  # GET /harvests/new.json
  def new
    @harvest = Harvest.new(harvested_at: Time.zone.today)
    @planting = Planting.find_by(slug: params[:planting_id]) if params[:planting_id]
    # using find_by_id here because it returns nil, unlike find
    @crop = Crop.find_by(id: params[:crop_id])
    respond_with(@harvest)
  end

  # GET /harvests/1/edit
  def edit
    @planting = @harvest.planting if @harvest.planting_id
  end

  # POST /harvests
  # POST /harvests.json
  def create
    @harvest.crop_id = @harvest.planting.crop_id if @harvest.planting_id
    flash[:notice] = I18n.t('harvests.created') if @harvest.save
    respond_with(@harvest)
  end

  # PUT /harvests/1
  # PUT /harvests/1.json
  def update
    flash[:notice] = I18n.t('harvests.updated') if @harvest.update(harvest_params)
    respond_with(@harvest)
  end

  # DELETE /harvests/1
  # DELETE /harvests/1.json
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
    else
      Harvest
    end.includes(:owner, :crop).paginate(page: params[:page])
  end

  def csv_filename
    specifics = (@owner ? "#{@owner.login_name}-" : @crop ? "#{@crop.name}-" : nil)
    "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_s(:number)}.csv"
  end
end
