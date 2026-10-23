# frozen_string_literal: true

# A few jobs to suggest to a member, and what they can do with each: add it to
# their jobs, snooze it, or say it is not for them.
class JobIdeasController < ApplicationController
  before_action :authenticate_member!

  def index
    @ideas = job_ideas.shown
    @more = job_ideas.more
    @skipped = skipped
    notepad = JobsNotepad.new(current_member)
    @job_groups = notepad.groups
    @done_this_week = notepad.done_this_week
  end

  def create
    idea = find_idea
    return redirect_to(job_ideas_path(skip: skipped), alert: t('job_ideas.gone')) unless idea

    JobIdeas::Add.new(current_member, idea).call
    redirect_to job_ideas_path(skip: skipped), notice: t('job_ideas.added', name: idea.name)
  end

  def hide
    key = params.require(:key)
    length = params[:length].to_s
    snoozed = JobIdeaDismissal::SNOOZES.key?(length)
    snoozed ? JobIdeaDismissal.snooze!(current_member, key, length) : JobIdeaDismissal.dismiss!(current_member, key)
    redirect_to job_ideas_path(skip: skipped), notice: t("job_ideas.hidden.#{snoozed ? length : 'dismissed'}")
  end

  private

  def job_ideas
    @job_ideas ||= JobIdeas.new(current_member, skip: skipped)
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
end
