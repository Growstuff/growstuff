# frozen_string_literal: true

# A planting's progress to harvest, in growing degree days, as a chart under its weather.
module WeatherHeatChartHelper
  include WeatherChartFrameHelper

  # The heat the crop has had added up day by day: a line that starts at 0 on the first day and climbs with each day's heat,
  # flat on a cold one, up to `needed`, the heat the crop needs to a first harvest. With it the Y axis is the share of that
  # heat, with a dashed line at 100%, and a marker where the line reaches it (see `weather_heat_ready`). `expected` carries the
  # line on through the days still to come, dotted, until it gets there. `degree_days` is a GrowingDegreeDays for the crop's base
  # temperature. `needed` can be nil when we don't know it, and the axis is then degree days.
  def weather_heat_chart(readings, degree_days:, from:, days:, needed: nil, seasons: [], expected: [], now: nil) # rubocop:disable Metrics/ParameterLists
    return if readings.empty?

    ready = weather_heat_ready(degree_days, needed, readings, expected)
    observed = weather_heat_totals(readings, degree_days)
    ahead = weather_heat_totals(weather_heat_expected_until(expected, ready), degree_days, start: observed.last.last)
    ahead.map! { |date, total| [date, [total, needed].min] } if needed
    scale = { top: weather_heat_top((observed + ahead).map(&:last).max, needed), step: weather_step(days), from: }
    lines = weather_heat_line(observed, scale, first: readings.first.date, css: nil)
    lines += weather_heat_line(observed.last(1) + ahead, scale, css: 'weather-expected') if ahead.any?
    weather_chart(safe_join([weather_season_bands(seasons, days), weather_heat_target_line(needed, scale), lines]),
                  t('plantings.show.weather_heat_chart_alt', total: observed.last.last.round, count: readings.size), 'weather-progress',
                  now: [weather_now_x(now, from, days), weather_heat_now_label(readings.last, observed.last.last)],
                  ticks: weather_heat_ticks(scale[:top], needed), overlay: weather_heat_ready_marker(ready, needed, scale))
  end

  # When the heat the crop needs is reached, as [date, :reached] if the weather so far has had it, or [date, :expected] if last
  # year's weather for the days to come gets there. Nil when we don't know what it needs, or it isn't reached.
  def weather_heat_ready(degree_days, needed, readings, expected)
    return unless needed

    if (date = degree_days.date_reaching(needed, readings))
      [date, :reached]
    elsif (date = degree_days.date_reaching(needed, readings + expected))
      [date, :expected]
    end
  end

  # "312 of about 600": the growing degree days a planting has had, against what its crop needs when we know that.
  def weather_heat_figure(so_far, needed)
    return number_with_delimiter(so_far) unless needed

    t('plantings.show.weather_heat_value', count: number_with_delimiter(so_far), needed: number_with_delimiter(needed))
  end

  # A sentence or two on how far the heat has got: its share of what the crop needs, and when it is, or should be, enough.
  # When it isn't, `through` is the last day of weather we expected, the day the planting is due to finish, and `ended` says
  # the planting is over, so there is none.
  def weather_heat_headline(so_far, needed, ready, through: nil, ended: false)
    return unless needed

    date, how = ready
    sentences = [t('plantings.show.weather_heat_percent', percent: (so_far * 100.0 / needed).round)]
    sentences << if how then t("plantings.show.weather_heat_enough_#{how}", date: l(date, format: :short))
                 elsif through then t('plantings.show.weather_heat_not_enough_expected', date: l(through, format: :short))
                 else t("plantings.show.weather_heat_not_enough_#{ended ? 'ended' : 'yet'}")
                 end
    sentences.join(' ')
  end

  private

  # [date, total so far] for each reading, in date order, with each day's heat added to `start`.
  def weather_heat_totals(readings, degree_days, start: 0.0)
    total = start
    readings.map { |reading| [reading.date, total += degree_days.for_day(reading)] }
  end

  # The expected days the line is drawn through: up to the day it reaches what the crop needs, and none when the weather so far
  # already has.
  def weather_heat_expected_until(expected, ready)
    date, how = ready
    return expected unless date
    return [] if how == :reached

    expected.select { |reading| reading.date <= date }
  end

  # The line through the days' totals, at the middle of each day's column. `first` is a day to start from at 0 before the
  # first total, at that day's left edge: the line begins on the axis.
  def weather_heat_line(totals, scale, css:, first: nil)
    points = totals.map { |date, total| [weather_heat_x(date, scale), weather_heat_y(total, scale)] }
    points.unshift([(first - scale[:from]) * scale[:step], weather_heat_y(0, scale)]) if first
    tag.polyline(class: ['weather-heat', css], points: points.map { |x, y| "#{x.round(1)},#{y}" }.join(' '))
  end

  def weather_heat_x(date, scale)
    ((date - scale[:from]) * scale[:step]) + (scale[:step] / 2)
  end

  def weather_heat_y(total, scale)
    (WEATHER_CHART_HEIGHT - (total.to_f / scale[:top] * WEATHER_CHART_HEIGHT)).round(1)
  end

  # The most the axis shows: the heat the crop needs, or a whole multiple of it when the heat so far has gone past, so the
  # percentages on the axis are round. Without a figure for the heat needed, the most so far, rounded up.
  def weather_heat_top(peak, needed)
    return [peak.ceil, 1].max unless needed

    needed * [(peak / needed).ceil, 1].max
  end

  # The Y axis: the share of what the crop needs, or degree days when we don't know it.
  def weather_heat_ticks(top, needed)
    unit, scale = needed ? ['%', 100.0 / needed] : ['', 1]
    [[0, weather_tick(top * scale, unit)], [0.5, weather_tick(top * scale / 2, unit)], [1, weather_tick(0, unit)]]
  end

  def weather_heat_target_line(needed, scale)
    return unless needed

    y = weather_heat_y(needed, scale)
    tag.line(class: 'weather-target-line', x1: 0, x2: WEATHER_CHART_WIDTH, y1: y, y2: y)
  end

  # A dot where the line reaches what the crop needs, and under it the day. HTML over the chart, since the chart is stretched
  # to fit and would squash a circle.
  def weather_heat_ready_marker(ready, needed, scale)
    return unless ready

    date, how = ready
    x = (weather_heat_x(date, scale) / WEATHER_CHART_WIDTH * 100).round(2)
    y = (weather_heat_y(needed, scale) * 100 / WEATHER_CHART_HEIGHT).round(2)
    label = t("plantings.show.weather_heat_ready_#{how}", date: l(date, format: :short))
    safe_join([tag.span('', class: 'weather-ready-dot', style: "left: #{x}%; top: #{y}%"),
               tag.span(label, class: "weather-ready-label weather-ready-label--#{x > 50 ? 'before' : 'after'}", style: "left: #{x}%")])
  end

  # What the heat had added up to by the latest observed day, for beside the "now" line.
  def weather_heat_now_label(reading, total)
    t('plantings.show.weather_now_heat', date: l(reading.date, format: :short), heat: weather_tick(total.round, ''))
  end
end
