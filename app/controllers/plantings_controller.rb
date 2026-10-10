# frozen_string_literal: true

class PlantingsController < DataController
  after_action :update_crop_medians, only: %i(create update destroy)
  after_action :update_planting_medians, only: :update
  respond_to :ics, only: [:index] # TODO: This can be shifted up when all relevant controllers respond to ical

  def index
    @show_all = params[:all] == '1'

    @owner = Member.find_by!(slug: params[:member_slug]) if params[:member_slug].present?
    @crop = Crop.find_by(slug: params[:crop_slug]) if params[:crop_slug]

    @plantings = plantings

    @filename = "Growstuff-#{specifics}Plantings-#{Time.zone.now.to_fs(:number)}.csv"
    respond_with(@plantings)
  end

  def show
    @photos = @planting.photos.includes(:owner).order(date_taken: :desc)
    @harvests = Harvest.where(planting_id: @planting.id).recent
    @current_activities = @planting.activities.current.includes(:owner).order(created_at: :desc)
    @finished_activities = @planting.activities.finished.includes(:owner).order(created_at: :desc)
    @matching_seeds = matching_seeds
    @crop = @planting.crop

    # TODO: use elastic search long/lat
    @neighbours = @planting.nearby_same_crop
      .where.not(id: @planting.id)
      .includes(:owner, :crop, :garden)
      .limit(6)

    if @planting.finished? && @planting.garden.plantings.current.none? && (@planting.updated_at + 2.weeks) > Time.zone.now
      @cultivate_soil_link = new_activity_path(name: 'Cultivate soil', garden_id: @planting.garden_id, category: "Soil Cultivation",
                                               description: "Recently finished #{@planting.crop.name} planting. Prepare for next planting.")
    end

    respond_with @planting
  end

  def new
    @planting = Planting.new(
      planted_at: Time.zone.today,
      owner:      current_member,
      garden:     current_member.gardens.first
    )
    @seed = Seed.find_by(slug: params[:seed_id]) if params[:seed_id]
    @crop = Crop.approved.find_by(id: params[:crop_id]) || Crop.new
    if params[:garden_id]
      @planting.garden = Garden.find_by(
        owner: current_member,
        id:    params[:garden_id]
      )
      # Arrived from a garden (e.g. "Plant something here"): no need to ask which.
      @garden_locked = @planting.garden.present?
    end

    respond_with @planting
  end

  def edit
    # the following are needed to display the form but aren't used
    @crop = Crop.new
    @gardens = @planting.owner.gardens.active.order_by_name
    render json: PlantingFormSerializer.new(@planting) if request.format.json?
  end

  def create
    @planting = Planting.new(planting_params)
    @planting.planted_at = Time.zone.now if @planting.planted_at.blank?
    @planting.owner = current_member
    @planting.crop = @planting.parent_seed.crop if @planting.parent_seed.present?
    # Only into your own gardens. A missing garden is left to the validation.
    authorize! :update, @planting.garden if @planting.garden.present?
    @planting.save
    return render_card_json(status: :created) if request.format.json?

    respond_with @planting
  end

  def update
    @planting.update(planting_params)
    return render_card_json(status: :ok) if request.format.json?

    respond_with @planting
  end

  def destroy
    @planting.destroy
    respond_with @planting, location: @planting.garden
  end

  def transplant
    # The `load_and_authorize_resource` in DataController will handle finding the
    # planting and authorizing the action.
    # We still need to authorize the new garden
    new_garden = Garden.find(params[:garden_id])
    authorize! :update, new_garden

    # Mark original planting as finished
    @planting.update(finished: true, finished_at: Time.zone.now)

    # Create a new planting
    new_planting = @planting.dup
    new_planting.garden = new_garden
    new_planting.slug = nil # let friendly_id generate a new slug
    new_planting.finished = false
    new_planting.finished_at = nil

    if new_planting.save
      redirect_to edit_planting_path(new_planting), notice: t('messages.transplant_success')
    else
      # if the save fails, we should probably roll back the finishing of the original planting
      @planting.update(finished: false, finished_at: nil)
      redirect_to @planting, alert: t('messages.transplant_error', errors: new_planting.errors.full_messages.to_sentence)
    end
  end

  private

  # Used by the React garden cards, which replace the garden's card with the
  # returned one, so a new or changed planting shows without a page reload.
  def render_card_json(status:)
    if @planting.errors.empty? && @planting.persisted?
      card = GardenCardSerializer.collection([@planting.garden], ability: current_ability, show_owner: false).first
      render json: { garden: card }, status: status
    else
      render json: { errors: @planting.errors }, status: :unprocessable_content
    end
  end

  def update_crop_medians
    @planting.crop.update_lifespan_medians if @planting.crop.present?
  end

  def update_planting_medians
    @planting.update_harvest_days!
  end

  def planting_params
    params[:planted_at] = parse_date(params[:planted_at]) if params[:planted_at]
    params.require(:planting).permit(
      :crop_id, :alternate_name_id, :description, :garden_id, :planted_at,
      :parent_seed_id,
      :quantity, :sunniness, :planted_from, :finished,
      :finished_at, :failed, :overall_rating
    )
  end

  def plantings
    p = if @owner
          @owner.plantings
        elsif @crop
          @crop.plantings
        else
          Planting
        end
    p = p.current unless @show_all
    p.joins(:owner, :crop, :garden)
      .order(created_at: :desc)
      .includes(:crop, :owner, :garden)
      .paginate(page: params[:page])
  end

  def matching_seeds
    @matching_seeds ||= Seed.where(crop: @planting.crop, owner: @planting.owner)
      .where('(finished_at IS NULL OR finished_at >= ?)', @planting.planted_at)
      .where('(saved_at IS NULL OR saved_at <= ?)', @planting.planted_at)
  end

  def specifics
    if @owner.present?
      "#{@owner.to_param}-"
    elsif @crop.present?
      "#{@crop.to_param}-"
    end
  end
end
