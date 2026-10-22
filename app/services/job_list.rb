# frozen_string_literal: true

# A member's jobs laid out as a notepad: overdue, today, the rest of this week,
# soon, some day, and done. Today, this week and some day are always there, as
# places to drop a job; each says which day a job dropped in it gets. Overdue,
# soon and done have no day of their own, so nothing is dropped there. A job
# crossed off stays where its day puts it, unless it has no day or that day has
# gone: then it moves to the bottom, to done, the latest day first and the ones
# without a day after.
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
    dated, undated = @jobs.partition(&:due_date)
    past, current = dated.partition { |job| job.due_date < @today }
    done_past, overdue = past.partition(&:finished)
    done_undated, someday = undated.partition(&:finished)
    done = done_past.reverse + done_undated.reverse
    now, later = current.partition { |job| job.due_date == @today }
    week, soon = later.partition { |job| ((@today + 1.day)..week_end).cover?(job.due_date) }

    [
      (Group.new(:overdue, overdue, nil, nil, false, nil) if overdue.any?),
      Group.new(:today, now, @today, nil, true, @today),
      (Group.new(:week, week, @today + 1.day, week_end, true, week_end) if week_end > @today),
      (Group.new(:soon, soon, nil, nil, false, nil) if soon.any?),
      Group.new(:someday, someday, nil, nil, true, nil),
      (Group.new(:done, done, nil, nil, false, nil) if done.any?)
    ].compact
  end

  private

  def week_end
    self.class.week_end(@today)
  end
end
