class Api::V1::HarvestsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource
  

  # GET /harvests.json
  api :GET, '/harvests/owner/:owner'
  api :GET, '/harvests/crop/:crop'
  api!
  def index
    @owner = Member.find_by_slug(params[:owner])
    @crop = Crop.find_by_slug(params[:crop])
    if @owner
      @harvests = @owner.harvests.includes(:owner, :crop)
    elsif @crop
      @harvests = @crop.harvests.includes(:owner, :crop)
    else
      @harvests = Harvest.includes(:owner, :crop)
    end

    respond_to do |format|
      format.json { render json: @harvests }
    end
  end

  # POST /harvests.json
  api!
  def create
    params[:harvest][:owner_id] = current_member.id
    params[:harvested_at] = parse_date(params[:harvested_at])
    @harvest = Harvest.new(harvest_params)

    respond_to do |format|
      if @harvest.save
        format.json { render json: @harvest, status: :created, location: @harvest }
      else
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /harvests/1.json
  def update
    @harvest = Harvest.find(params[:id])

    respond_to do |format|
      if @harvest.update(harvest_params)
        format.json { head :no_content }
      else
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /harvests/1.json
  api!
  def destroy
    @harvest = Harvest.find(params[:id])
    @harvest.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def harvest_params
    params.require(:harvest).permit(:crop_id, :harvested_at, :description, :owner_id,
    :quantity, :unit, :weight_quantity, :weight_unit, :plant_part_id, :slug, :si_weight)
  end
end
