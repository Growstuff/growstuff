# frozen_string_literal: true

class JobIdeas
  # The time of year a source looks back to: the fortnight starting on today's day
  # in each of the years before, as far back as MAX_YEARS.
  module PastYears
    WINDOW = 14.days
    MAX_YEARS = 5

    private

    # One range of days for each earlier year, the most recent first.
    def past_windows
      (1..MAX_YEARS).map { |years| (@today - years.years)..(@today - years.years + WINDOW) }
    end
  end
end
