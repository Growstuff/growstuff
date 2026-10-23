# frozen_string_literal: true

# A few jobs to suggest to a member, and what they can do with each: add it to
# their jobs, snooze it, or say it is not for them. On the page, or as an overlay
# on their jobs, where each choice is sent without leaving and answered with the
# ideas that are left, the jobs that were added and the member's jobs as they now
# are.
class JobIdeasController < ApplicationController
  before_action :authenticate_member!

  def index
    load_ideas
    return render(partial: 'job_ideas/list') if request.xhr?

    notepad = JobsNotepad.new(current_member)
    @job_groups = notepad.groups
    @done_this_week = notepad.done_this_week
  end

  def create
    idea = find_idea
    added = idea ? JobIdeas::Add.new(current_member, idea).call : []
    changed(added, idea ? t('job_ideas.added', name: idea.name) : t('job_ideas.gone'))
  end

  def hide
    key = params.require(:key)
    length = params[:length].to_s
    snoozed = JobIdeaDismissal::SNOOZES.key?(length)
    snoozed ? JobIdeaDismissal.snooze!(current_member, key, length) : JobIdeaDismissal.hide!(current_member, key)
    changed([], t("job_ideas.hidden.#{snoozed ? length : 'dismissed'}"))
  end

  private

  def job_ideas
    @job_ideas ||= JobIdeas.new(current_member, skip: skipped)
  end

  def load_ideas
    @ideas = job_ideas.shown
    @more = job_ideas.more
    @skipped = skipped
  end

  # The sources the member has switched off, kept in the address.
  def skipped
    Array(params[:skip]) & JobIdeas::SWITCHES.keys
  end

  # The idea asked for, as the member would be offered it now. Anything else, or
  # an idea no longer on offer, is not made into a job.
  def find_idea
    job_ideas.ideas.find { |idea| idea.key == params[:key] }
  end

  def changed(added, notice)
    return redirect_to(job_ideas_path(skip: skipped), notice:) unless request.xhr?

    JobIdeas.forget_count(current_member)
    @job_ideas = nil
    load_ideas
    render json: overlay_json(added)
  end

  # The member's jobs, as they now are, to show those that were added.
  def jobs_groups
    groups = JobsNotepad.new(current_member).groups
    render_to_string(partial: 'jobs/notepad_groups', formats: [:html], locals: { groups:, in_garden: false })
  end

  def overlay_json(added)
    count = @ideas.size + @more
    {
      list: render_to_string(partial: 'job_ideas/list', formats: [:html]),
      groups: (jobs_groups if added.any?),
      count:, banner: t('job_ideas.banner', count:), added_label: t('job_ideas.added_to_jobs', count: added.size),
      added: added.map { |job| { id: job.id, name: job.name, due: (l(job.due_date, format: '%-d %b') if job.due_date) } }
    }
  end
end
