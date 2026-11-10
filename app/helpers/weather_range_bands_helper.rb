# frozen_string_literal: true

# The temperatures a crop grows best in and survives, according to EcoCrop, as bands across a planting's temperature
# chart, so the weather can be read against them.
module WeatherRangeBandsHelper
  include WeatherChartFrameHelper

  # Whether the weather is inside the crop's ranges decides the badge's colour.
  WEATHER_STATUS_COLOURS = { best: 'success', cool: 'warning', warm: 'warning', too_cold: 'danger', too_hot: 'danger',
                             ok: 'secondary' }.freeze

  # { optimal: [low, high], absolute: [low, high] } for a crop, leaving out what EcoCrop has nothing on. The best range
  # needs both its ends; the absolute one can have only one, and is then open at the other. Nil with neither.
  def weather_temperature_ranges(crop)
    data = crop&.ecocrop_data
    return unless data

    ranges = {}
    ranges[:optimal] = [data.topmn, data.topmx] if data.topmn && data.topmx
    ranges[:absolute] = [data.tmin, data.tmax] if data.tmin || data.tmax
    ranges.presence
  end

  # A badge saying whether the latest observed day was inside the crop's best temperature range, a bit outside it, or
  # outside what it survives, going by the day's average of its high and low. Nil without ranges or a day to judge.
  def weather_range_badge(readings, ranges, crop:)
    reading = ranges && readings.rfind { |candidate| candidate.temp_max_c && candidate.temp_min_c }
    status = reading && weather_range_status(weather_mean(reading), ranges)
    return unless status

    title = t('plantings.show.weather_status_title', date: l(reading.date, format: :short))
    css = "badge text-bg-#{WEATHER_STATUS_COLOURS.fetch(status)} ms-1"
    tag.span(t("plantings.show.weather_status_#{status}", crop: crop.name), class: css, title:)
  end

  # "12 of 20", the days with both a high and a low whose average was in the best range; nil without a best range.
  def weather_best_days(readings, ranges)
    optimal = ranges&.dig(:optimal)
    days = readings.select { |reading| reading.temp_max_c && reading.temp_min_c }
    return unless optimal && days.any?

    t('plantings.show.weather_best_days_value', count: days.count { |reading| weather_mean(reading).between?(*optimal) }, total: days.size)
  end

  private

  # :best, :cool or :warm against the best range, or :too_cold or :too_hot beyond what the crop survives. :ok when
  # it survives the temperature and there is no best range to compare. Absolute limits come first.
  def weather_range_status(mean, ranges)
    optimal = ranges[:optimal]
    low, high = ranges[:absolute]
    return :too_cold if low && mean < low
    return :too_hot if high && mean > high
    return :ok unless optimal
    return :cool if mean < optimal.first

    mean > optimal.last ? :warm : :best
  end

  # The day's average temperature, taken as the middle of its high and low.
  def weather_mean(reading)
    (reading.temp_max_c + reading.temp_min_c) / 2.0
  end

  # The temperatures a chart has to reach to show its ranges.
  def weather_range_values(ranges)
    ranges ? ranges.values.flatten.compact : []
  end

  # A band across the whole chart for each range, the wider one behind.
  def weather_range_bands(ranges, scale)
    return unless ranges

    safe_join(%i(absolute optimal).filter_map do |kind|
      next unless ranges[kind]

      top, bottom = weather_range_edges(ranges[kind], scale)
      tag.rect(class: "weather-band weather-band--#{kind}", x: 0, y: top, width: WEATHER_CHART_WIDTH, height: bottom - top)
    end)
  end

  # What each band is, in its right-hand corner: the best range under its top edge, the survivable one above its bottom edge.
  def weather_range_labels(ranges, scale)
    return unless ranges

    safe_join(%i(optimal absolute).filter_map do |kind|
      next unless ranges[kind]

      top, bottom = weather_range_edges(ranges[kind], scale)
      y = kind == :optimal ? top : bottom
      tag.span(weather_range_text(kind, ranges[kind]), class: "weather-band-label weather-band-label--#{kind}",
                                                       style: "top: #{(y * 100 / WEATHER_CHART_HEIGHT).round(2)}%")
    end)
  end

  # "Grows best 18–32°", or "Survives ≥ 7°" for a range open at one end.
  def weather_range_text(kind, ends)
    low, high = ends
    range = if low && high then "#{weather_tick(low, '')}–#{weather_tick(high, '°')}"
            elsif low then "≥ #{weather_tick(low, '°')}"
            else "≤ #{weather_tick(high, '°')}"
            end
    t("plantings.show.weather_#{kind}_range", range:)
  end

  # How far down the chart a range starts and ends, [top, bottom]: the chart's edge for an open end.
  def weather_range_edges(ends, scale)
    low, high = ends
    [high ? weather_range_y(high, scale) : 0, low ? weather_range_y(low, scale) : WEATHER_CHART_HEIGHT]
  end

  def weather_range_y(degrees, scale)
    (WEATHER_CHART_HEIGHT - ((degrees - scale[:low]).to_f / scale[:span] * WEATHER_CHART_HEIGHT)).clamp(0, WEATHER_CHART_HEIGHT).round(1)
  end
end
