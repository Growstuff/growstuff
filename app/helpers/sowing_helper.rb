# frozen_string_literal: true

# A packet's sowing facts, as the packet would write them.
module SowingHelper
  # The seasons of the northern hemisphere, as months. The southern hemisphere's are the same
  # six months on: spring there is September to November.
  NORTHERN_SEASONS = { 'Spring' => [3, 4, 5], 'Summer' => [6, 7, 8], 'Autumn' => [9, 10, 11], 'Winter' => [12, 1, 2] }.freeze

  # The months to sow in, as runs: "Oct–Feb", or "Mar–Apr, Sep–Oct". A run goes on round the end
  # of the year, and all twelve is "All year". Nothing, if there are none.
  def sow_months_text(months)
    months = Array(months).sort
    return if months.empty?
    return 'All year' if months.size == 12

    runs = months.slice_when { |earlier, later| later != earlier + 1 }.to_a
    runs = [runs.last + runs.first, *runs[1...-1]] if runs.size > 1 && runs.first.first == 1 && runs.last.last == 12
    runs.map { |run| run.one? ? sow_month_name(run.first) : "#{sow_month_name(run.first)}\u2013#{sow_month_name(run.last)}" }.join(', ')
  end

  # A range of days, "7–14", or the one number if there is only one. Nothing, if there is none.
  def days_range_text(min, max)
    return if min.blank? && max.blank?
    return (min || max).to_s if min.blank? || max.blank? || min == max

    "#{min}\u2013#{max}"
  end

  # The seasons as months for the grower's hemisphere, to tick several months at once: nothing
  # where we don't know which hemisphere that is, rather than guessing.
  def season_months(latitude)
    return if latitude.blank?

    NORTHERN_SEASONS.transform_values { |months| latitude.negative? ? months.map { |month| ((month + 5) % 12) + 1 } : months }
  end

  private

  def sow_month_name(month)
    Date::ABBR_MONTHNAMES[month]
  end
end
