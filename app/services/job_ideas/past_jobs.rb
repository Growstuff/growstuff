# frozen_string_literal: true

# Jobs a member finished at this time of year in earlier years: in the fortnight
# starting on today's day. Left out are jobs they already have open, and jobs made
# from a template, which has its own idea. A job done in several years is one
# idea, dated the latest time.
class JobIdeas
  class PastJobs
    include PastYears

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      done_jobs.group_by { |job, _done_on| key_for(job) }.filter_map do |key, rows|
        job, done_on = rows.max_by(&:last)
        next if open_names.include?(job.name.downcase)

        Idea.new(kind: :past_job, key:, name: job.name, crop: crop_of(job), on: done_on, years: rows.map { |_, day| day.year }.uniq.size)
      end
    end

    private

    # Each job with the day it was done. A job finished before the time was
    # recorded was done on the day it was due.
    def done_jobs
      jobs = past_windows.map { |window| finished_in(window) }.reduce(:or)
      jobs.includes(:jobbable).map { |job| [job, job.finished_at&.to_date || job.due_date] }
    end

    def finished_in(window)
      @member.jobs.where(finished: true, crop_job_step_id: nil)
        .where('jobs.finished_at BETWEEN ? AND ? OR (jobs.finished_at IS NULL AND jobs.due_date BETWEEN ? AND ?)',
               window.first.beginning_of_day, window.last.end_of_day, window.first, window.last)
    end

    def open_names
      @open_names ||= @member.jobs.active.pluck(:name).map(&:downcase)
    end

    def key_for(job)
      "past_job:#{job.name.downcase}:#{crop_of(job)&.id}"
    end

    # The crop a job is about, if it is about one.
    def crop_of(job)
      job.jobbable.is_a?(Crop) ? job.jobbable : job.jobbable.try(:crop)
    end
  end
end
