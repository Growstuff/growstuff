# frozen_string_literal: true

class SeedsController < DataController
  def index
    @owner = Member.find_by(slug: params[:member_slug]) if params[:member_slug].present?
    @crop = Crop.find_by(slug: params[:crop_slug]) if params[:crop_slug].present?
    @planting = Planting.find_by(slug: params[:planting_id]) if params[:planting_id].present?

    @show_all = (params[:all] == '1')

    @filename = csv_filename
    @seeds = seeds.order(created_at: :desc).includes(:owner, :crop).paginate(page: params[:page])

    respond_with(@seeds)
  end

  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc).paginate(page: params[:page])
    respond_with(@seed)
  end

  def new
    @seed = Seed.new

    if params[:planting_id]
      @planting = Planting.find_by(slug: params[:planting_id])
    else
      @crop = Crop.find_or_initialize_by(id: params[:crop_id])
    end
    respond_with(@seed)
  end

  def edit; end

  def create
    @seed = Seed.new(seed_params)
    @seed.owner = current_member
    @seed.crop = @seed.parent_planting.crop if @seed.parent_planting
    flash[:notice] = "Successfully added #{@seed.crop} seed to your stash." if @seed.save
    if params[:return] == 'planting'
      respond_with(@seed, location: @seed.parent_planting)
    else
      respond_with(@seed)
    end
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

  def seeds
    records = Seed.all
    records = records.where(owner: @owner) if @owner.present?
    records = records.where(crop: @crop) if @crop.present?
    records = records.where(parent_planting: @planting) if @planting.present?
    records = records.active unless @show_all
    records
  end

  def seed_params
    params.require(:seed).permit(
      :crop_id, :description, :quantity, :plant_before,
      :parent_planting_id, :saved_at,
      :days_until_maturity_min, :days_until_maturity_max,
      :organic, :gmo,
      :heirloom, :tradable_to, :slug,
      :finished, :finished_at
    )
  end

  def csv_filename
    if @owner
      "Growstuff-#{@owner.to_param}-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    else
      "Growstuff-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    end
  end
end
