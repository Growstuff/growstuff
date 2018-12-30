class SeedsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :csv, only: :index
  respond_to :rss, only: :index

  # GET /seeds
  # GET /seeds.json
  def index
    @owner = Member.find_by(slug: params[:owner])
    @crop = Crop.find_by(slug: params[:crop])

    @seeds = @seeds.where(owner: @owner) if @owner.present?
    @seeds = @seeds.where(crop: @crop) if @crop.present?

    @seeds = @seeds.order(created_at: :desc).includes(:owner, :crop).paginate(page: params[:page])

    @filename = csv_filename

    respond_with(@seeds)
  end

  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc).paginate(page: params[:page])
    respond_with(@seed)
  end

  def new
    @planting = Planting.find_by(slug: params[:planting_id]) if params[:planting_id].present?
    @crop = Crop.find(params[:crop_id]) if params[:crop_id].present?

    respond_with(@seed)
  end

  def edit; end

  def create
    @seed = Seed.new(seed_params)
    @seed.owner = current_member
    @seed.crop = @seed.parent_planting.crop if @seed.parent_planting
    flash[:notice] = "Successfully added #{@seed.crop} seed to your stash." if @seed.save
    respond_with(@seed)
  end

  def update
    flash[:notice] = 'Seed was successfully updated.' if @seed.update(seed_params)
    respond_with(@seed)
  end

  def destroy
    @seed.destroy
    respond_with(@seed)
  end

  private

  def seed_params
    params.require(:seed).permit(
      :crop_id, :description, :quantity, :plant_before,
      :parent_planting_id,
      :days_until_maturity_min, :days_until_maturity_max,
      :organic, :gmo,
      :heirloom, :tradable_to, :slug,
      :finished, :finished_at
    )
  end

  def csv_filename
    if @owner
      "Growstuff-#{@owner}-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    else
      "Growstuff-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    end
  end
end
