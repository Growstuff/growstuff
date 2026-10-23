# frozen_string_literal: true

module JobsHelper
  # The day shown beside a job: when it is due, or, once it is crossed off, when
  # that was ("done last Tuesday"). A job crossed off before the day was recorded
  # shows the day it was due.
  def job_date_label(job, today = Time.zone.today)
    return job_due_label(job, today) unless job.finished && job.finished_at

    day = job.finished_at.to_date
    day == today ? t('jobs.pad.done_today') : t('jobs.pad.done_on', day: job_day_label(day, today))
  end

  # When a job is due, as it would be said on a notepad.
  def job_due_label(job, today = Time.zone.today)
    job_day_label(job.due_date, today) if job.due_date.present?
  end

  # A day as it would be said on a notepad: "Sat" for the next few days, "last
  # Tuesday" when it was in the past week, and the date for anything further off
  # or further back.
  def job_day_label(date, today = Time.zone.today)
    if date.between?(today - 6.days, today - 1.day)
      t('jobs.due.last', day: l(date, format: '%A'))
    elsif date.between?(today, today + 6.days)
      l(date, format: '%a')
    else
      l(date, format: '%a %-d %b')
    end
  end

  # What the notepad's script says when a job is crossed off. The count is filled
  # in by the script, which knows it only once the server has answered.
  def job_celebrations
    levels = %w(one two three many).index_with do |level|
      { lead: t("jobs.celebrate.#{level}.lead"), note: t("jobs.celebrate.#{level}.note") }
    end

    # The name and count are left as tokens for the script to fill in.
    name = '%{name}' # rubocop:disable Style/FormatStringToken
    count = '%{count}' # rubocop:disable Style/FormatStringToken

    { levels:, slow: t('jobs.pad.slow'), crossed_off: t('jobs.celebrate.crossed_off', name:), undo: t('jobs.celebrate.undo'),
      done: { one: t('jobs.celebrate.done.one'), other: t('jobs.celebrate.done.other', count:) } }
  end

  # The line under the notepad, beside the snail.
  def job_snail_caption(done_this_week)
    [t('jobs.pad.slow'), (t('jobs.celebrate.done', count: done_this_week) if done_this_week.positive?)].compact.join(' ')
  end

  def job_overdue?(job, today = Time.zone.today)
    job.due_date.present? && job.due_date < today && !job.finished
  end
end
