# frozen_string_literal: true

# A member's jobs laid out as a notepad: overdue, today, the rest of this week,
# soon, some day, and done. Today, this week and some day are always there, as
# places to drop a job; each says which day a job dropped in it gets. Overdue,
# soon and done have no day of their own, so nothing is dropped there. A job
# crossed off stays where its day puts it, unless it has no day or that day has
# gone: then it moves to the bottom, to done, the one finished last first. Jobs
# crossed off in the page being looked at are pinned: they stay where they were
# until the page is loaded again, so a tick never makes a row jump.
class JobList
  Group = Struct.new(:key, :jobs, :from, :to, :droppable, :drop_date, keyword_init: true) do
    alias_method :droppable?, :droppable
  end

  # The last day of the week, a Sunday.
  def self.week_end(today)
    today.end_of_week(:monday)
  end

  def initialize(jobs, today: Time.zone.today, pinned: [])
    @jobs = jobs
    @today = today
    @pinned = pinned
  end

  def groups
    dated, undated = @jobs.partition(&:due_date)
    past, current = dated.partition { |job| job.due_date < @today }
    done_past, overdue = past.partition { |job| settled?(job) }
    done_undated, someday = undated.partition { |job| settled?(job) }
    done = (done_past + done_undated).sort_by { |job| done_time(job) }.reverse
    now, later = current.partition { |job| job.due_date == @today }
    week, soon = later.partition { |job| ((@today + 1.day)..week_end).cover?(job.due_date) }

    [
      (Group.new(key: :overdue, jobs: overdue) if overdue.any?),
      Group.new(key: :today, jobs: now, from: @today, droppable: true, drop_date: @today),
      (Group.new(key: :week, jobs: week, from: @today + 1.day, to: week_end, droppable: true, drop_date: week_end) if week_end > @today),
      (Group.new(key: :soon, jobs: soon) if soon.any?),
      Group.new(key: :someday, jobs: someday, droppable: true),
      (Group.new(key: :done, jobs: done) if done.any?)
    ].compact
  end

  private

  # When a job was crossed off, or if that wasn't recorded, when it was due. Jobs
  # with neither are the oldest.
  def done_time(job)
    job.finished_at || job.due_date&.in_time_zone || Time.zone.at(0)
  end

  # Crossed off, and so ready to move to done.
  def settled?(job)
    job.finished && @pinned.exclude?(job.id)
  end

  def week_end
    self.class.week_end(@today)
  end
end
