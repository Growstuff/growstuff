# frozen_string_literal: true

# A member's jobs laid out as a notepad: what is for this weekend, what is soon,
# and what has no day yet. Finished jobs are a list of their own.
class JobList
  Group = Struct.new(:key, :jobs, :from, :to)

  def initialize(jobs, today: Time.zone.today)
    @jobs = jobs
    @today = today
  end

  # The groups that have any jobs, in the order they are shown.
  def groups
    dated, someday = @jobs.partition(&:due_date)
    weekend, soon = dated.partition { |job| weekend?(job.due_date) }
    [
      Group.new(:weekend, weekend, *weekend_days),
      Group.new(:soon, soon),
      Group.new(:someday, someday)
    ].select { |group| group.jobs.any? }
  end

  # The Saturday and Sunday this weekend: the one coming, or the one going on.
  def weekend_days
    saturday = @today.saturday? || @today.sunday? ? @today.beginning_of_week(:monday) + 5.days : @today.next_occurring(:saturday)
    [saturday, saturday + 1.day]
  end

  private

  def weekend?(date)
    weekend_days.include?(date)
  end
end
