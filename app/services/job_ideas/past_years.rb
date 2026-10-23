# frozen_string_literal: true

class JobIdeas
  # The time of year a source looks back to: the fortnight starting on today's day
  # in each of the years before, as far back as MAX_YEARS. Also what the sources
  # share about jobs, which are finished in a window and which the member already
  # has open.
  module PastYears
    WINDOW = 14.days
    MAX_YEARS = 5
    # Done in the window by the time it was crossed off or, if that was not
    # recorded, the day it was due.
    FINISHED_IN = '(jobs.finished_at BETWEEN ? AND ? OR (jobs.finished_at IS NULL AND jobs.due_date BETWEEN ? AND ?))'

    private

    # One range of days for each earlier year, the most recent first.
    def past_windows
      (1..MAX_YEARS).map { |years| (@today - years.years)..(@today - years.years + WINDOW) }
    end

    # The finished jobs in `jobs` that were done in any of the windows.
    def finished_in(jobs, windows)
      windows.map do |window|
        jobs.where(FINISHED_IN, window.first.beginning_of_day, window.last.end_of_day, window.first, window.last)
      end.reduce(:or)
    end

    # The names of the jobs the member has open, lower case.
    def open_names
      @open_names ||= @member.jobs.active.pluck(:name).to_set(&:downcase)
    end
  end
end
