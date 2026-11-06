# frozen_string_literal: true

# What goes around a weather chart's data: the "now" line, the Y axis and the SVG itself.
module WeatherChartFrameHelper
  WEATHER_CHART_WIDTH = 600
  WEATHER_CHART_HEIGHT = 80 # also the charts' height in _plantings.scss

  private

  # How wide one day is on the chart axis.
  def weather_step(days)
    WEATHER_CHART_WIDTH.to_f / days
  end

  # A line down the middle of today's column, or nil when there is no today to show.
  def weather_now_x(now, from, days)
    (((now - from) * weather_step(days)) + (weather_step(days) / 2)).round(2) if now
  end

  # What the latest observed day was like, for beside the "now" line. Weather runs a few days behind, so it is dated.
  def weather_now_temperatures(reading)
    return unless reading&.temp_max_c && reading.temp_min_c

    t('plantings.show.weather_now_temperature', date: l(reading.date, format: :short),
                                                high: weather_degrees(reading.temp_max_c), low: weather_degrees(reading.temp_min_c))
  end

  def weather_now_line(position)
    tag.line(class: 'weather-now', x1: position, x2: position, y1: 0, y2: WEATHER_CHART_HEIGHT) if position
  end

  # The label sits beside the line, on whichever side has room.
  def weather_now_caption(position, label)
    return unless position && label

    side = position > WEATHER_CHART_WIDTH / 2 ? 'before' : 'after'
    tag.span(label, class: "weather-now-label weather-now-label--#{side}",
                    style: "left: #{(position * 100 / WEATHER_CHART_WIDTH).round(2)}%")
  end

  # A value on the Y axis: whole numbers without the trailing ".0".
  def weather_tick(value, unit)
    "#{value.round(1).to_s.delete_suffix('.0')}#{' ' if unit == 'mm'}#{unit}"
  end

  # A faint line across the chart at each tick but the first and last, which are the chart's edges.
  def weather_gridlines(ticks)
    safe_join(ticks[1...-1].map do |fraction, _label|
      y = (fraction * WEATHER_CHART_HEIGHT).round(2)
      tag.line(class: 'weather-grid', x1: 0, x2: WEATHER_CHART_WIDTH, y1: y, y2: y)
    end)
  end

  # The Y axis' numbers, down the chart's left edge. `fraction` is how far down the chart each one sits.
  def weather_axis_labels(ticks)
    tag.div(class: 'weather-axis', aria: { hidden: true }) do
      safe_join(ticks.map { |fraction, label| tag.span(label, style: "top: #{fraction * 100}%") })
    end
  end

  # `now` is the "now" line's x and its label, as [x, label], when there is one to draw. `ticks` are the Y axis'
  # [how far down, label] pairs.
  def weather_chart(content, description, css, now: nil, ticks: [])
    x, label = now
    svg = tag.svg(safe_join([content, weather_gridlines(ticks), weather_now_line(x)]), class: "weather-chart #{css}",
                                                                                      viewBox: weather_view_box,
                                                                                      preserveAspectRatio: 'none', role: 'img',
                                                                                      'aria-label': description)
    tag.div(safe_join([svg, weather_axis_labels(ticks), weather_now_caption(x, label)]), class: 'weather-chart-frame')
  end

  def weather_view_box
    "0 0 #{WEATHER_CHART_WIDTH} #{WEATHER_CHART_HEIGHT}"
  end
end
