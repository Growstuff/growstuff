# frozen_string_literal: true

module JobsHelper
  # When a job is due, as it would be said on a notepad: "Sat" for the next few
  # days, "last Tuesday" when it was in the past week, and the date for anything
  # further off or further back.
  def job_due_label(job, today = Time.zone.today)
    date = job.due_date
    return if date.blank?

    if date.between?(today - 6.days, today - 1.day)
      t('jobs.due.last', day: l(date, format: '%A'))
    elsif date.between?(today, today + 6.days)
      l(date, format: '%a')
    else
      l(date, format: '%a %-d %b')
    end
  end

  def job_overdue?(job, today = Time.zone.today)
    job.due_date.present? && job.due_date < today && !job.finished
  end
end
