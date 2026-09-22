# frozen_string_literal: true

class GardensController < DataController
  # Anyone can look at a member's inactive gardens, as they can their current ones.
  # A garden's layout is public in the same way its show page is.
  skip_before_action :authenticate_member!, only: %i(inactive layout)
  skip_load_and_authorize_resource only: :inactive

  def index
    @owner = Member.find_by!(slug: params[:member_slug]) if params[:member_slug].present?
    @show_jump_to = params[:member_slug].present? || false

    @gardens = @gardens.includes(:owner)
    @gardens = @gardens.active
    if @owner.present?
      @gardens = @gardens.left_joins(:garden_collaborators)
      @gardens = @gardens.where(owner: @owner).or(@gardens.where(garden_collaborators: { member: @owner }))
    end
    @gardens = @gardens.where.not(members: { confirmed_at: nil })
      .order(:name).paginate(page: params[:page])
    respond_with(@gardens)
  end

  # A member's gardens that are no longer active, as a gallery of what they grew.
  def inactive
    @owner = Member.confirmed.find_by!(slug: params[:member_slug])
    owned = Garden.inactive.where(owner: @owner)
    collaborating = Garden.inactive.where(id: GardenCollaborator.where(member: @owner).select(:garden_id))
    @gardens = owned.or(collaborating)
      .includes(:owner, plantings: { crop: { parent: :parent } })
      .order(updated_at: :desc)
      .paginate(page: params[:page], per_page: 12)
  end

  def show
    @current_plantings = @garden.plantings.current.where.not(failed: true).includes(:crop, :owner).order(planted_at: :desc)
    @current_activities = @garden.activities.current.includes(:owner).order(created_at: :desc)
    @finished_activities = @garden.activities.finished.includes(:owner).order(created_at: :desc)
    @finished_plantings = @garden.plantings.finished.includes(:crop)
    @suggested_companions = Crop.approved.where(
      id: CropCompanion.where(crop_a_id: @current_plantings.select(:crop_id)).select(:crop_b_id)
    ).order(:name)
    respond_with(@garden)
  end

  # A map of where things are planted in the bed. Anyone who can see the garden
  # can see its layout; only the owner and collaborators can rearrange it.
  def layout
    @owner = @garden.owner
    @editable = can?(:update_layout, @garden)
    @layout = GardenLayoutSerializer.new(@garden, editable: @editable, resizable: can?(:update, @garden)).as_json
    # The island reloads this after planting something new, since the planting
    # form answers with a garden card rather than a layout.
    render json: @layout if request.format.json?
  end

  # Saves the whole arrangement in one go, rather than a request per drag.
  #
  # Every plant is taken off the grid before the new positions are applied, so
  # any plant the request leaves out ends up off the bed. A single bad placement
  # rolls the whole thing back, leaving the bed as it was rather than half
  # rearranged.
  #
  # A planting behaves like a stack: dragging one off it puts a plant on the
  # bed, and the planting's quantity follows from how many plants it ends up
  # with rather than being typed in.
  def update_layout
    @layout_errors = {}
    placements = layout_params
    saved = Garden.transaction do
      clear_positions
      apply_placements(placements)
      raise ActiveRecord::Rollback if @layout_errors.present?

      sync_quantities
      true
    end
    return render json: { errors: @layout_errors }, status: :unprocessable_content unless saved

    render json: GardenLayoutSerializer.new(@garden.reload, editable: true, resizable: can?(:update, @garden)).as_json
  end

  def new
    @garden = Garden.new
    respond_with(@garden)
  end

  def edit
    return render json: GardenFormSerializer.new(@garden, member: current_member) if request.format.json?

    respond_with(@garden)
  end

  def create
    @garden.owner_id = current_member.id
    if @garden.save
      link = new_activity_path(name: 'Weed the garden bed', garden_id: @garden.id, due_date: 2.weeks.from_now.to_date)
      flash[:notice] = t('gardens.created_prompt_html', link: link).html_safe
    end
    respond_with(@garden)
  end

  def update
    saved = @garden.update(garden_params)
    return render_card_json(saved) if request.format.json?

    flash[:notice] = I18n.t('gardens.updated') if saved
    respond_with(@garden)
  end

  def destroy
    @garden.destroy
    flash[:notice] = I18n.t('gardens.deleted')
    redirect_to(member_gardens_path(@garden.owner))
  end

  def fetch_wikidata
    if @garden.populate_wikidata_info
      @garden.save
      flash[:notice] = "Wikidata information updated."
    else
      flash[:alert] = "Could not find Wikidata information for this location."
    end
    redirect_to @garden
  end

  private

  # Takes every plant off the grid first, so the new arrangement is checked
  # against a clean bed and two plants can swap cells in one save.
  #
  # The callers read the plants back afterwards rather than clearing the copies
  # they already hold. Assigning nil to a loaded record and then assigning its
  # old position back leaves it unchanged as far as dirty tracking is concerned,
  # so the save would do nothing and the plant would stay off the grid — which
  # is only visible as every plant but the one just dragged disappearing.
  def clear_positions
    Plant.where(planting_id: @garden.plantings.current.select(:id))
      .update_all(bed_x: nil, bed_y: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  # Collects the errors of any placement that wouldn't save, for the response.
  def apply_placements(placements)
    existing = @garden.placed_or_owned_plants.index_by(&:id)
    # Plants this request already accounts for, so pulling from a stack doesn't
    # grab one that another placement is about to use.
    spoken_for = placements.filter_map { |placement| placement[:plant_id].presence&.to_i }.to_set

    placements.each do |placement|
      plant = plant_for(placement, existing, spoken_for)
      next if plant.nil? # the error is already recorded

      plant.assign_attributes(bed_x: placement[:bed_x], bed_y: placement[:bed_y])
      @layout_errors[plant.id || :new] = plant.errors.full_messages unless plant.save
    end
  end

  # A placement names either a plant already on the bed, or just the planting it
  # came off, which means one more of that crop.
  def plant_for(placement, existing, spoken_for)
    return known_plant(placement, existing) if placement[:plant_id].present?

    planting = @garden.plantings.current.find_by(id: placement[:planting_id])
    if planting.nil?
      @layout_errors[placement[:planting_id]] = ['is not a planting in this garden']
      return nil
    end

    take_from_stack(planting, spoken_for)
  end

  def known_plant(placement, existing)
    plant = existing[placement[:plant_id].to_i]
    @layout_errors[placement[:plant_id]] = ['is not a plant in this garden'] if plant.nil?
    plant
  end

  # Uses up a plant the planting already has before making another, so a
  # planting that says it has nine tomatoes maps those nine first.
  def take_from_stack(planting, spoken_for)
    spare = planting.plants.find { |plant| spoken_for.exclude?(plant.id) }
    spoken_for << spare.id if spare
    spare || planting.plants.build
  end

  # The number of plants is whatever ended up on and off the bed, so dragging
  # one more onto the grid is what makes the planting bigger.
  def sync_quantities
    @garden.plantings.current.includes(:plants).find_each do |planting|
      count = planting.plants.size
      planting.update_column(:quantity, count) if planting.quantity != count # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Permits each placement on its own rather than the whole params hash: the
  # route's :member_slug and :slug, and the empty :garden that wrap_parameters
  # adds to JSON requests, would otherwise count as unpermitted and raise.
  def layout_params
    placements = params[:placements]
    return [] unless placements.is_a?(Array)

    placements.map do |placement|
      placement.permit(:plant_id, :planting_id, :bed_x, :bed_y).to_h.symbolize_keys
    end
  end

  # Used by the React garden cards, which replace the garden's card with the
  # returned one. No flash: nothing redirects, so it would turn up on the next page.
  def render_card_json(saved)
    if saved
      card = GardenCardSerializer.collection([@garden], ability: current_ability, show_owner: false).first
      render json: { garden: card }
    else
      render json: { errors: @garden.errors }, status: :unprocessable_content
    end
  end

  def garden_params
    params.require(:garden).permit(
      :name, :slug, :description, :active,
      :location, :latitude, :longitude, :area, :area_unit, :garden_type_id,
      :location_wikidata_id, :lowest_temp_c, :highest_temp_c,
      :grid_columns, :grid_rows
    )
  end
end
