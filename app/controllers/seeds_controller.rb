# frozen_string_literal: true

class SeedsController < DataController
  def index
    @seeds = Seed.all

    if params[:member_slug].present?
      @owner = Member.find_by!(slug: params[:member_slug])
      @seeds = @seeds.where(owner_id: @owner.id)
    end

    if params[:crop_slug].present?
      @crop = Crop.find_by(slug: params[:crop_slug])
      @seeds = @seeds.where(crop_id: @crop.id) if @crop
    end

    if params[:planting_id].present?
      @planting = Planting.find_by(slug: params[:planting_id])
      @seeds = @seeds.where(parent_planting_id: @planting.id) if @planting
    end

    @seeds = @seeds.where(tradable_to: params[:tradeable_to]) if params[:tradeable_to].present?

    @show_all = (params[:all] == '1')
    @seeds = @seeds.current unless @show_all

    @filename = csv_filename
    @seeds = @seeds.includes(:crop, :owner)
                   .order(created_at: :desc)
                   .paginate(page: params[:page], per_page: 30)

    respond_with(@seeds)
  end

  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc, id: :desc).paginate(page: params[:page], per_page: 30)
    respond_with(@seed)
  end

  def new
    @seed = Seed.new
    @seed.source = 'my own seed saving'

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
    @seed.source ||= 'my own seed saving'
    @seed.finished ||= false
    @seed.owner = current_member
    @seed.crop = @seed.parent_planting.crop if @seed.parent_planting
    flash[:notice] = t('seeds.added_to_stash', crop: @seed.crop) if @seed.save
    if params[:return] == 'planting'
      respond_with(@seed, location: @seed.parent_planting)
    else
      respond_with(@seed)
    end
  end

  def update
    flash[:notice] = t('seeds.updated') if @seed.update(seed_params)
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
      :organic, :gmo, :source,
      :heirloom, :tradable_to, :slug,
      :finished, :finished_at
    )
  end

  def csv_filename
    if @owner
      "Growstuff-#{@owner.to_param}-Seeds-#{Time.zone.now.to_fs(:number)}.csv"
    else
      "Growstuff-Seeds-#{Time.zone.now.to_fs(:number)}.csv"
    end
  end
end
