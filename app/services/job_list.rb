# frozen_string_literal: true

# A member's jobs laid out as a notepad: overdue, today, the rest of this week,
# this weekend, next weekend, later, some day, and done. All but overdue and done
# are always there, as places to drop a job; each says which day a job dropped in
# it gets. Overdue and done have no day of their own, so nothing is dropped there. A job
# crossed off stays where its day puts it, unless it has no day or that day has
# gone: then it moves to the bottom, to done, the one finished last first. Jobs
# crossed off in the page being looked at are pinned: they stay where they were
# until the page is loaded again, so a tick never makes a row jump. Only the
# DONE_SHOWN most recently done are shown; the rest are older, behind "show more".
class JobList
  DONE_SHOWN = 5

  Group = Struct.new(:key, :jobs, :from, :to, :droppable, :drop_date, keyword_init: true) do
    alias_method :droppable?, :droppable

    # The jobs to show straight away. Only done is cut short.
    def shown
      key == :done ? jobs.first(DONE_SHOWN) : jobs
    end

    # The jobs behind "show more".
    def older
      key == :done ? jobs.drop(DONE_SHOWN) : []
    end
  end

  # The last day of the week, a Sunday.
  def self.week_end(today)
    today.end_of_week(:monday)
  end

  # The first day of the weekend still to come: tomorrow, if today is the Saturday.
  def self.weekend_start(today)
    [week_end(today) - 1.day, today + 1.day].max
  end

  # The day a job moved to Later gets: three weeks out.
  def self.later_date(today)
    today + 3.weeks
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
    week, later = later.partition { |job| ((@today + 1.day)..friday).cover?(job.due_date) }
    weekend, later = later.partition { |job| (weekend_from..week_end).cover?(job.due_date) }
    next_weekend, later = later.partition { |job| ((saturday + 7.days)..(week_end + 7.days)).cover?(job.due_date) }

    [
      (Group.new(key: :overdue, jobs: overdue) if overdue.any?),
      Group.new(key: :today, jobs: now, from: @today, droppable: true, drop_date: @today),
      (Group.new(key: :week, jobs: week, from: @today + 1.day, to: friday, droppable: true, drop_date: friday) if friday > @today),
      (if week_end > @today
         Group.new(key: :weekend, jobs: weekend, from: weekend_from, to: week_end, droppable: true,
                   drop_date: weekend_from)
       end),
      Group.new(key: :next_weekend, jobs: next_weekend, from: saturday + 7.days, to: week_end + 7.days, droppable: true,
                drop_date: saturday + 7.days),
      Group.new(key: :later, jobs: later, droppable: true, drop_date: self.class.later_date(@today)),
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

  def friday
    week_end - 2.days
  end

  def saturday
    week_end - 1.day
  end

  def weekend_from
    self.class.weekend_start(@today)
  end
end
