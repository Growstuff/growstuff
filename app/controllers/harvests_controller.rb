class HarvestsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /harvests
  # GET /harvests.json
  def index
    @owner = Member.find_by(slug: params[:owner])
    @crop = Crop.find_by(slug: params[:crop])
    @harvests = if @owner
                  @owner.harvests.includes(:owner, :crop)
                elsif @crop
                  @crop.harvests.includes(:owner, :crop)
                else
                  Harvest.includes(:owner, :crop)
                end

    respond_to do |format|
      format.html { @harvests = @harvests.paginate(page: params[:page]) }
      format.json { render json: @harvests }
      format.csv do
        specifics = (@owner ? "#{@owner.login_name}-" : @crop ? "#{@crop.name}-" : nil)
        @filename = "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_s(:number)}.csv"
        render csv: @harvests
      end
    end
  end

  def show
    @matching_plantings = matching_plantings if @harvest.owner == current_member
  end

  # GET /harvests/new
  # GET /harvests/new.json
  def new
    @harvest = Harvest.new('harvested_at' => Time.zone.today)
    @planting = Planting.find_by(slug: params[:planting_id]) if params[:planting_id]

    # using find_by_id here because it returns nil, unlike find
    @crop = Crop.find_or_initialize_by(id: params[:crop_id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @harvest }
    end
  end

  # GET /harvests/1/edit
  def edit
    @planting = @harvest.planting if @harvest.planting_id
  end

  # POST /harvests
  # POST /harvests.json
  def create
    @harvest.crop_id = @harvest.planting.crop_id if @harvest.planting_id

    respond_to do |format|
      if @harvest.save
        format.html { redirect_to @harvest, notice: I18n.t('harvests.created') }
        format.json { render json: @harvest, status: :created, location: @harvest }
      else
        format.html { render action: "new" }
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /harvests/1
  # PUT /harvests/1.json
  def update
    respond_to do |format|
      if @harvest.update(harvest_params)
        format.html { redirect_to @harvest, notice: I18n.t('harvests.updated') }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /harvests/1
  # DELETE /harvests/1.json
  def destroy
    @harvest.destroy

    respond_to do |format|
      format.html { redirect_to harvests_url }
      format.json { head :no_content }
    end
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
  end
end
