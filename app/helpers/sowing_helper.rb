# frozen_string_literal: true

# A packet's sowing facts, as the packet would write them.
module SowingHelper
  # The seasons as months, for each hemisphere, named as the packet would.
  NORTHERN_SEASONS = SeasonsHelper::SEASON_MONTHS[:northern].transform_keys { |season| season.to_s.capitalize }.freeze
  SOUTHERN_SEASONS = SeasonsHelper::SEASON_MONTHS[:southern].transform_keys { |season| season.to_s.capitalize }.freeze

  # The months to sow in, as runs: "Oct–Feb", or "Mar–Apr, Sep–Oct". A run goes on round the end
  # of the year, and all twelve is "All year". Nothing, if there are none.
  def sow_months_text(months)
    months = Array(months).sort
    return if months.empty?
    return t('seeds.ui.all_year') if months.size == 12

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

    latitude.negative? ? SOUTHERN_SEASONS : NORTHERN_SEASONS
  end

  private

  def sow_month_name(month)
    t('seeds.ui.month_abbreviations')[month - 1]
  end
end
