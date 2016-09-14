class Api::V1::SeedsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /seeds.json
  api!
  api :GET, '/seeds/owner/:owner'
  api :GET, '/seeds/crop/:crop'
  def index
    @owner = Member.find_by_slug(params[:owner])
    @crop = Crop.find_by_slug(params[:crop])
    if @owner
      @seeds = @owner.seeds.includes(:owner, :crop).paginate(page: params[:page])
    elsif @crop
      @seeds = @crop.seeds.includes(:owner, :crop).paginate(page: params[:page])
    else
      @seeds = Seed.includes(:owner, :crop).paginate(page: params[:page])
    end

    render json: @seeds
  end

  # GET /seeds/1.json
  api!
  def show
    @seed = Seed.find(params[:id])

    render json: @seed
  end

  # POST /seeds.json
  api!
  def create
    params[:seed][:owner_id] = current_member.id
    @seed = Seed.new(seed_params)

    if @seed.save
      render json: @seed, status: :created, location: @seed
    else
      render json: @seed.errors, status: :unprocessable_entity
    end
  end

  # PUT /seeds/1.json
  api!
  def update
    @seed = Seed.find(params[:id])

    if @seed.update(seed_params)
      head :no_content
    else
      render json: @seed.errors, status: :unprocessable_entity
    end
  end

  # DELETE /seeds/1.json
  api!
  def destroy
    @seed = Seed.find(params[:id])
    @seed.destroy

    head :no_content
  end

  private

  def seed_params
    params.require(:seed).permit(
      :owner_id, :crop_id, :description, :quantity, :plant_before,
      :days_until_maturity_min, :days_until_maturity_max, :organic, :gmo,
      :heirloom, :tradable_to, :slug)
  end
end
