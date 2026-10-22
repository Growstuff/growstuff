# frozen_string_literal: true

# A member's jobs laid out as a notepad: today, the rest of this week, soon, and
# some day. Today, this week and some day are always there, as places to drop a
# job; each says which day a job dropped in it gets. Soon has no day of its own,
# so nothing is dropped there.
class JobList
  Group = Struct.new(:key, :jobs, :from, :to, :droppable, :drop_date) do
    alias_method :droppable?, :droppable
  end

  # The last day of the week, a Sunday.
  def self.week_end(today)
    today.end_of_week(:monday)
  end

  def initialize(jobs, today: Time.zone.today)
    @jobs = jobs
    @today = today
  end

  def groups
    dated, someday = @jobs.partition(&:due_date)
    now, later = dated.partition { |job| job.due_date == @today }
    week, soon = later.partition { |job| ((@today + 1.day)..week_end).cover?(job.due_date) }

    [
      Group.new(:today, now, @today, nil, true, @today),
      (Group.new(:week, week, @today + 1.day, week_end, true, week_end) if week_end > @today),
      (Group.new(:soon, soon, nil, nil, false, nil) if soon.any?),
      Group.new(:someday, someday, nil, nil, true, nil)
    ].compact
  end

  def week_end
    self.class.week_end(@today)
  end
end
