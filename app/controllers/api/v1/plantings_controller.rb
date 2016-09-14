class Api::V1::PlantingsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  api!
  api :GET, '/plantings/owner/:owner'
  api :GET, '/plantings/crop/:crop'
  def index
    @owner = Member.find_by_slug(params[:owner])
    @crop = Crop.find_by_slug(params[:crop])
    if @owner
      @plantings = @owner.plantings.includes(:owner, :crop, :garden).paginate(page: params[:page])
    elsif @crop
      @plantings = @crop.plantings.includes(:owner, :crop, :garden).paginate(page: params[:page])
    else
      @plantings = Planting.includes(:owner, :crop, :garden).paginate(page: params[:page])
    end

    render json: @plantings
  end

  # GET /plantings/1.json
  api!
  def show
    @planting = Planting.includes(:owner, :crop, :garden, :photos).friendly.find(params[:id])

    render json: @planting
  end

  # POST /plantings.json
  api!
  def create
    params[:planted_at] = parse_date(params[:planted_at])
    @planting = Planting.new(planting_params)
    @planting.owner = current_member

    if @planting.save
      @planting.update_attribute(:days_before_maturity, update_days_before_maturity(@planting, planting_params[:crop_id]))
      render json: @planting, status: :created, location: @planting
      expire_fragment("homepage_stats")
    else
      render json: @planting.errors, status: :unprocessable_entity
    end
  end

  # PUT /plantings/1.json
  api!
  def update
    @planting = Planting.find(params[:id])
    params[:planted_at] = parse_date(params[:planted_at])

    if @planting.update(planting_params)
      @planting.update_attribute(:days_before_maturity, update_days_before_maturity(@planting, planting_params[:crop_id]))
      head :no_content
    else
      render json: @planting.errors, status: :unprocessable_entity
    end
  end

  # DELETE /plantings/1.json
  api!
  def destroy
    @planting = Planting.find(params[:id])
    @garden = @planting.garden
    @planting.destroy
    expire_fragment("homepage_stats")

    head :no_content
  end

  private

  def planting_params
    params.require(:planting).permit(:crop_id, :description, :garden_id, :planted_at,
    :quantity, :sunniness, :planted_from, :owner_id, :finished,
    :finished_at)
  end

  def update_days_before_maturity(planting, crop_id)
    if planting.finished_at.nil?
      planting.calculate_days_before_maturity(planting, crop_id)
    else
      (planting.finished_at - planting.planted_at).to_i
    end
  end
end
