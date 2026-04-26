# frozen_string_literal: true

class ActivitiesController < DataController
  def index
    @show_all = params[:all] == '1'

    @activities = Activity.includes(:owner, :garden, planting: :crop).order(created_at: :desc)
    @activities = @activities.active unless @show_all

    if params[:member_slug]
      @owner = Member.find_by(slug: params[:member_slug])
      @activities = @activities.where(owner_id: @owner.id) if @owner.present?
    end

    @activities = @activities.paginate(page: params[:page], per_page: 30)

    @filename = "Growstuff-#{specifics}Activities-#{Time.zone.now.to_fs(:number)}.csv"
    respond_with(@activities)
  end

  def show
    if @activity.finished? && @activity.owner == current_member && (@activity.updated_at + 2.weeks) > Time.now
      @repeat_link = new_activity_path(
        name:        @activity.name,
        garden_id:   @activity.garden_id,
        planting_id: @activity.planting_id,
        category:    @activity.category,
        description: @activity.description,
        due_date:    2.weeks.from_now.to_date
      )
    end

    respond_with @activity
  end

  def new
    @activity = Activity.new(
      owner:    current_member,
      due_date: Date.today
    )
    @activity.name = params[:name] if params[:name]
    @activity.description = params[:description] if params[:description]
    @activity.category = params[:category] if params[:category]
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
    @activity.due_date ||= Date.today

    if @activity.save
      if params[:repeat_times].to_i > 0
        repeat_times = params[:repeat_times].to_i
        repeat_weeks = params[:repeat_weeks].to_i

        repeat_times.times do |i|
          new_activity = @activity.dup
          new_activity.due_date = @activity.due_date + (i + 1) * repeat_weeks.weeks
          new_activity.save
        end
      end
    end

    respond_with @activity
  end

  def update
    @activity.update(activity_params)
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
      :garden_id, :planting_id, :due_date,
      :repeat_times, :repeat_weeks
    )
  end

  def specifics
    return if @owner.blank?

    "#{@owner.to_param}-"
  end
end
