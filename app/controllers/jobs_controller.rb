# frozen_string_literal: true

class JobsController < DataController
  def index
    @show_all = params[:all] == '1'

    @jobs = Job.includes(:owner).order(created_at: :desc)
    @jobs = @jobs.active unless @show_all

    if params[:member_slug].present?
      @owner = Member.find_by!(slug: params[:member_slug])
      @jobs = @jobs.where(owner_id: @owner.id)
    end

    if notepad?
      load_notepad
    else
      @jobs = @jobs.paginate(page: params[:page], per_page: 30)
    end

    @filename = "Growstuff-#{specifics}Jobs-#{Time.zone.now.to_fs(:number)}.csv"
    respond_with(@jobs)
  end

  def new
    @job = Job.new(
      owner:    current_member,
      due_date: Date.today
    )
    @job.name = params[:name] if params[:name]
    @job.description = params[:description] if params[:description]
    @job.due_date = params[:due_date] if params[:due_date]
    if params[:garden_id]
      @job.garden = Garden.find_by(
        owner: current_member,
        id:    params[:garden_id]
      )
    end

    if params[:planting_id]
      @job.planting = Planting.find_by(
        owner: current_member,
        id:    params[:planting_id]
      )
    end

    respond_with @job
  end

  def edit
    # the following are needed to display the form but aren't used
    @gardens = @job.owner.gardens.active.order_by_name
    @plantings = @job.owner.plantings.active
  end

  def create
    @job = Job.new(job_params)
    @job.owner = current_member
    @job.due_date ||= Date.today

    if request.xhr?
      return head :unprocessable_entity unless @job.save

      return render_notepad(:created)
    end

    if @job.save
      if params[:repeat_times].to_i > 0
        repeat_times = params[:repeat_times].to_i
        repeat_weeks = params[:repeat_weeks].to_i

        repeat_times.times do |i|
          new_job = @job.dup
          new_job.due_date = @job.due_date + (i + 1) * repeat_weeks.weeks
          new_job.save
        end
      end
    end

    respond_with @job, location: after_save_path
  end

  def update
    if request.xhr?
      return head :unprocessable_entity unless @job.update(job_params)

      return render_notepad(:ok)
    end

    @job.update(job_params)
    respond_with @job, location: after_save_path
  end

  def destroy
    @job.destroy
    respond_with @job, location: after_save_path
  end

  private

  # There is no page for a single job: saving or deleting one goes back to the
  # list it is on.
  def after_save_path
    member_jobs_path(@job.owner)
  end

  # A member looking at their own jobs sees them as a notepad. The data formats,
  # and anyone else's jobs, are lists.
  def notepad?
    @owner.present? && @owner == current_member && request.format.html?
  end

  # Adding or moving a job from the notepad sends back the notepad's groups, so
  # the page can show the change without reloading.
  def render_notepad(status)
    @owner = current_member
    load_notepad
    render partial: 'jobs/notepad_groups', locals: { groups: @job_groups }, status:
  end

  def load_notepad
    @jobs = Job.where(owner: @owner).includes(:garden, planting: :crop)
      .order(Arel.sql('finished IS TRUE'), Arel.sql('due_date IS NULL'), :due_date, :created_at)
    @job_groups = JobList.new(@jobs).groups
  end

  def job_params
    params.require(:job).permit(
      :name, :description, :finished,
      :garden_id, :planting_id, :due_date,
      :repeat_times, :repeat_weeks
    )
  end

  def specifics
    return if @owner.blank?

    "#{@owner.to_param}-"
  end
end
