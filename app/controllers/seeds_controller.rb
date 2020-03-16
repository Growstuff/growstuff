# frozen_string_literal: true

class SeedsController < DataController
  def index
    where = {}

    if params[:member_slug].present?
      @owner = Member.find_by(slug: params[:member_slug])
      where['owner_id'] = @owner.id
    end

    if params[:crop_slug].present?
      @crop = Crop.find_by(slug: params[:crop_slug])
      where['crop_id'] = @crop.id
    end

    if params[:planting_id].present?
      @planting = Planting.find_by(slug: params[:planting_id])
      where['parent_planting'] = @planting.id
    end

    @show_all = (params[:all] == '1')
    where['finished'] = false unless @show_all

    @filename = csv_filename
    @seeds = Seed.search(
      where:    where,
      page:     params[:page],
      limit:    30,
      boost_by: [:created_at],
      load:     false
    )

    respond_with(@seeds)
  end

  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc).paginate(page: params[:page])
    respond_with(@seed)
  end

  def new
    @seed = Seed.new

    if params[:planting_slug]
      @planting = Planting.find_by(slug: params[:planting_slug])
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
