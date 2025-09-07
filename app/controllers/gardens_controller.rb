# frozen_string_literal: true

class GardensController < DataController
  def index
    @owner = Member.find_by(slug: params[:member_slug])
    @show_all = params[:all] == '1'
    @show_jump_to = params[:member_slug].present? || false

    @gardens = @gardens.includes(:owner)
    @gardens = @gardens.active unless @show_all
    if @owner.present?
      @gardens = @gardens.left_joins(:garden_collaborators)
      @gardens = @gardens.where(owner: @owner).or(@gardens.where(garden_collaborators: { member: @owner }))
    end
    @gardens = @gardens.where.not(members: { confirmed_at: nil })
      .order(:name).paginate(page: params[:page])
    respond_with(@gardens)
  end

  def show
    @current_plantings = @garden.plantings.current.where.not(failed: true).includes(:crop, :owner).order(planted_at: :desc)
    @current_activities = @garden.activities.current.includes(:owner).order(created_at: :desc)
    @finished_plantings = @garden.plantings.finished.includes(:crop)
    @suggested_companions = Crop.approved.where(
      id: CropCompanion.where(crop_a_id: @current_plantings.select(:crop_id)).select(:crop_b_id)
    ).order(:name)
    respond_with(@garden)
  end

  def new
    @garden = Garden.new
    respond_with(@garden)
  end

  def edit
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
    flash[:notice] = I18n.t('gardens.updated') if @garden.update(garden_params)
    respond_with(@garden)
  end

  def destroy
    @garden.destroy
    flash[:notice] = I18n.t('gardens.deleted')
    redirect_to(member_gardens_path(@garden.owner))
  end

  private

  def garden_params
    params.require(:garden).permit(
      :name, :slug, :description, :active,
      :location, :latitude, :longitude, :area, :area_unit, :garden_type_id
    )
  end
end
