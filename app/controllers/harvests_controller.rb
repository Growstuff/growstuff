# frozen_string_literal: true

class HarvestsController < DataController
  after_action :update_crop_medians, only: %i(create update destroy)

  def index
    @harvests = Harvest.all

    if params[:member_slug].present?
      @owner = Member.find_by!(slug: params[:member_slug])
      @harvests = @harvests.where(owner_id: @owner.id)
    end

    if params[:crop_slug]
      @crop = Crop.find_by(slug: params[:crop_slug])
      @harvests = @harvests.where(crop_id: @crop.id) if @crop
    end

    if params[:planting_slug]
      @planting = Planting.find_by(slug: params[:planting_slug])
      @harvests = @harvests.where(planting_id: @planting.id) if @planting
    end

    @harvests = @harvests.includes(:crop, :owner, :plant_part)

    @harvests = @harvests.recent.paginate(page: params[:page], per_page: 100)

    @filename = csv_filename

    respond_with(@harvests)
  end

  def show
    @matching_plantings = matching_plantings if @harvest.owner == current_member
    @photos = @harvest.photos.order(created_at: :desc).paginate(page: params[:page])
    respond_with(@harvest)
  end

  def new
    @harvest = Harvest.new(new_harvest_params.merge(harvested_at: Time.zone.today))

    if params[:planting_slug].present?
      @planting = Planting.find_by(slug: params[:planting_slug])
      @harvest.planting ||= @planting
    end

    if @harvest.planting
      @harvest.crop ||= @harvest.planting.crop
    elsif params[:crop_id].present?
      @harvest.crop ||= Crop.find_by(id: params[:crop_id])
    elsif params[:crop_slug].present?
      @harvest.crop ||= Crop.find_by(slug: params[:crop_slug])
    end

    @planting = @harvest.planting
    @crop = @harvest.crop
    return render json: HarvestFormSerializer.new(@harvest) if request.format.json? && @crop.present?

    respond_with(@harvest)
  end

  def edit
    @planting = @harvest.planting if @harvest.planting_id
    @crop = @harvest.crop
    respond_with(@harvest)
  end

  def create
    @harvest.crop_id = @harvest.planting.crop_id if @harvest.planting_id
    @harvest.harvested_at = Time.zone.now if @harvest.harvested_at.blank?
    @planting = @harvest.planting
    @crop = @harvest.crop
    update_planting_rating if @harvest.save
    return render_card_json if request.format.json? && @planting.present?

    if params[:return] == 'planting'
      respond_with(@harvest, location: @harvest.planting)
    else
      respond_with(@harvest)
    end
  end

  def update
    update_planting_rating if @harvest.update(harvest_params)
    respond_with(@harvest)
  end

  def destroy
    @harvest.destroy
    respond_with(@harvest)
  end

  private

  # Used by the React garden cards, which replace the garden's card with the
  # returned one, so the planting's badges and predictions follow the harvest
  # without a page reload.
  def render_card_json
    if @harvest.persisted?
      card = GardenCardSerializer.collection([@planting.garden], ability: current_ability, show_owner: false).first
      render json: { garden: card }, status: :created
    else
      render json: { errors: @harvest.errors }, status: :unprocessable_content
    end
  end

  def harvest_params
    params.require(:harvest)
      .permit(:planting_id, :crop_id, :harvested_at, :description,
              :quantity, :unit, :weight_quantity, :weight_unit,
              :plant_part_id, :slug, :si_weight, :overall_rating)
      .merge(owner_id: current_member.id)
  end

  def new_harvest_params
    return {} if params[:harvest].blank?

    params.require(:harvest)
      .permit(:planting_id, :crop_id, :harvested_at, :description,
              :quantity, :unit, :weight_quantity, :weight_unit,
            :plant_part_id, :slug, :si_weight, :overall_rating)
      .merge(owner_id: current_member.id)
  end

  def matching_plantings
    Planting.where(crop: @harvest.crop, owner: @harvest.owner)
      .where('(planted_at IS NULL OR planted_at <= ?)', @harvest.harvested_at)
      .where('(finished_at IS NULL OR finished_at >= ?)', @harvest.harvested_at)
  end

  def csv_filename
    specifics = if @owner
                  "#{@owner.to_param}-"
                elsif @crop
                  "#{@crop.to_param}-"
                end
    "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_fs(:number)}.csv"
  end

  def update_crop_medians
    # We only update medians to predict plantings
    # if this harvest is not linked to a planting, then do nothing
    return if @harvest.planting.nil?

    @harvest.planting.update_harvest_days!
    @harvest.crop.update_harvest_medians
  end

  def update_planting_rating
    return if @harvest.planting.nil? || params[:harvest][:overall_rating].blank?

    @harvest.planting.update(overall_rating: params[:harvest][:overall_rating])
  end
end
