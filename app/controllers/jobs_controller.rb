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
    @job = Job.new(new_job_params.to_h.reverse_merge(due_date: Time.zone.today))
    @job.owner = current_member
    @job.garden = nil unless @job.garden&.owner == current_member
    @job.planting = nil unless @job.planting&.owner == current_member

    respond_with @job
  end

  def create
    @job = Job.new(job_params)
    @job.owner = current_member
    @job.due_date ||= Time.zone.today
    saved = @job.save

    return render_notepad(:created) if request.xhr? && saved
    return head :unprocessable_entity if request.xhr?

    repeat if saved
    respond_with @job, location: after_save_path
  end

  def update
    updated = @job.update(job_params)

    return render_notepad(:ok) if request.xhr? && updated
    return head :unprocessable_entity if request.xhr?

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
    response.set_header('X-Jobs-Done-This-Week', current_member.jobs.finished_this_week.count.to_s)
    render partial: 'jobs/notepad_groups', locals: { groups: @job_groups }, status:
  end

  def load_notepad
    @jobs = Job.where(owner: @owner).includes(:garden, :jobbable)
      .order(Arel.sql('finished IS TRUE'), Arel.sql('due_date IS NULL'), :due_date, :created_at)
    @job_groups = JobList.new(@jobs).groups
  end

  def job_params
    params.require(:job).permit(:name, :description, :finished, :due_date,
                                :garden_id, :planting_id, :jobbable_type, :jobbable_id)
  end

  # What a link to "new job" can fill in ahead of time, as Copy does.
  def new_job_params
    params.permit(:name, :description, :due_date, :garden_id, :planting_id)
  end

  # "Repeat how many times, every how many weeks" on the form: copies of the job
  # on later days.
  def repeat
    weeks = params[:repeat_weeks].to_i.weeks
    params[:repeat_times].to_i.times do |i|
      @job.dup.tap { |copy| copy.due_date = @job.due_date + ((i + 1) * weeks) }.save
    end
  end

  def specifics
    return if @owner.blank?

    "#{@owner.to_param}-"
  end
end
