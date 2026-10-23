# frozen_string_literal: true

# Jobs a member finished in the next two weeks of a year ago, unless they already
# have an open job of that name or it was made from a template, which has its own
# idea. A job done more than once is one idea, for the first time.
class JobIdeas
  class LastYear
    WINDOW = 14.days

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      done_jobs.uniq { |job, _done_on| key_for(job) }.filter_map do |job, done_on|
        next if open_names.include?(job.name.downcase)

        Idea.new(kind: :last_year, key: key_for(job), name: job.name, crop: crop_of(job), on: done_on)
      end
    end

    private

    # Each job with the day it was done, earliest first. A job finished before
    # the time was recorded was done on the day it was due.
    def done_jobs
      from = @today - 1.year
      to = from + WINDOW
      jobs = @member.jobs.where(finished: true, crop_job_step_id: nil).includes(:jobbable)
        .where('jobs.finished_at BETWEEN ? AND ? OR (jobs.finished_at IS NULL AND jobs.due_date BETWEEN ? AND ?)',
               from.beginning_of_day, to.end_of_day, from, to)
      jobs.map { |job| [job, job.finished_at&.to_date || job.due_date] }.sort_by(&:last)
    end

    def open_names
      @open_names ||= @member.jobs.active.pluck(:name).map(&:downcase)
    end

    def key_for(job)
      "last_year:#{job.name.downcase}:#{crop_of(job)&.id}"
    end

    # The crop a job is about, if it is about one.
    def crop_of(job)
      job.jobbable.is_a?(Crop) ? job.jobbable : job.jobbable.try(:crop)
    end
  end
end
