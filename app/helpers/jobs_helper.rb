# frozen_string_literal: true

module JobsHelper
  # When a job is due, as it would be said on a notepad: "Sat" for the next few
  # days, "was Tue" when it is late, and the date for anything further off.
  def job_due_label(job, today = Time.zone.today)
    date = job.due_date
    return if date.blank?

    if date < today
      t('jobs.due.was', day: l(date, format: '%a'))
    elsif date < today + 7.days
      l(date, format: '%a')
    else
      l(date, format: '%a %-d %b')
    end
  end

  def job_overdue?(job, today = Time.zone.today)
    job.due_date.present? && job.due_date < today && !job.finished
  end
end
