# frozen_string_literal: true

class ActivitiesController < DataController
  def index
    @show_all = params[:all] == '1'

    where = {}
    where['active'] = true unless @show_all

    if params[:member_slug]
      @owner = Member.find_by(slug: params[:member_slug])
      where['owner_id'] = @owner.id unless @owner.nil?
    end

    @activities = Activity.search(
      where:,
      page:     params[:page],
      limit:    30,
      boost_by: [:created_at],
      load:     false
    )
    @filename = "Growstuff-#{specifics}Activities-#{Time.zone.now.to_fs(:number)}.csv"
    respond_with(@activities)
  end

  def show
    respond_with @activity
  end

  def new
    @activity = Activity.new(
      owner:    current_member,
      due_date: Date.today
    )
    @activity.name = params[:name] if params[:name]
    @activity.due_date = params[:due_date] if params[:due_date]
    if params[:garden_id]
      @activity.garden = Garden.find_by(
        owner: current_member,
        id:    params[:garden_id]
      )
    end

    if params[:planting_id]
      @activity.planting = Planting.find_by(
        owner: current_member,
        id:    params[:planting_id]
      )
    end

    respond_with @activity
  end

  def edit
    # the following are needed to display the form but aren't used
    @gardens = @activity.owner.gardens.active.order_by_name
    @plantings = @activity.owner.plantings.active
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.owner = current_member
    @activity.save
    respond_with @activity
  end

  def update
    if @activity.update(activity_params)
      if activity_params[:finished].present?
        link = new_activity_path(
          name:        @activity.name,
          garden_id:   @activity.garden_id,
          planting_id: @activity.planting_id,
          due_date:    2.weeks.from_now.to_date
        )
        flash[:notice] = t('activities.finished_prompt_html', link: link).html_safe
      end
    end
    respond_with @activity
  end

  def destroy
    @activity.destroy
    respond_with @activity, location: @activity.garden
  end

  private

  def activity_params
    params.require(:activity).permit(
      :name, :description, :category, :finished,
      :garden_id, :planting_id, :due_date
    )
  end

  def specifics
    return if @owner.blank?

    "#{@owner.to_param}-"
  end
end
