# frozen_string_literal: true

module PlantingsHelper
  include SeasonsHelper

  WEATHER_CHART_WIDTH = 600
  WEATHER_CHART_HEIGHT = 80

  # The headline figures for a run of weather readings, as text, leaving out any we have no data for.
  def weather_summary(readings)
    rain = readings.filter_map(&:rainfall_mm)
    hottest = readings.filter_map(&:temp_max_c).max
    coldest = readings.filter_map(&:temp_min_c).min
    soil = readings.filter_map(&:soil_temp_c)
    {
      rain:      ("#{number_with_precision(rain.sum, precision: 0, delimiter: ',')} mm" if rain.any?),
      hottest:   (weather_degrees(hottest) if hottest),
      coldest:   (weather_degrees(coldest) if coldest),
      soil_temp: (weather_degrees(soil.sum / soil.size) if soil.any?),
      days:      readings.size
    }.compact
  end

  # How many days the weather charts' X axis spans, from the planting date: the same stretch as the
  # progress bar above them, which is the crop's expected lifespan, or longer when the planting is running late.
  def weather_axis_days(planting)
    [planting.expected_lifespan.to_i, planting.age_in_days.to_i, 1].max
  end

  # The seasons along the chart axis for a garden at this latitude: [{ season:, first:, last: }], where
  # first and last are the days (0 is `from`) each one covers. Empty when we don't know the hemisphere.
  def weather_seasons(latitude, from:, days:)
    half = hemisphere(latitude)
    return [] unless half

    (0...days).chunk_while { |a, b| season_in(half, from + a) == season_in(half, from + b) }.map do |run|
      { season: season_in(half, from + run.first), first: run.first, last: run.last }
    end
  end

  def weather_degrees(celsius)
    "#{celsius.round(1)}°C"
  end

  # Daily rainfall as bars, placed by date along an axis that starts on `from` and runs for `days`.
  def weather_rain_chart(readings, from:, days:, seasons: [])
    top = [readings.filter_map(&:rainfall_mm).max.to_f, 1].max
    step = WEATHER_CHART_WIDTH.to_f / days
    bars = readings.filter_map do |reading|
      next unless reading.rainfall_mm&.positive?

      height = (reading.rainfall_mm / top * WEATHER_CHART_HEIGHT).round(1)
      tag.rect(x: ((reading.date - from) * step).round(2), y: WEATHER_CHART_HEIGHT - height,
               width: [step, 0.6].max.round(2), height:)
    end
    weather_chart(safe_join(bars), t('plantings.show.weather_rain_chart_alt', max: top.round, count: readings.size), 'weather-rain',
                  seasons:, days:)
  end

  # The daily high and low as two lines, on the same axis.
  def weather_temperature_chart(readings, from:, days:, seasons: [])
    values = readings.flat_map { |reading| [reading.temp_max_c, reading.temp_min_c] }.compact
    return if values.empty?

    low = values.min
    span = [values.max - low, 1].max
    lines = { 'weather-high' => :temp_max_c, 'weather-low' => :temp_min_c }.map do |css, column|
      tag.polyline(class: css, points: weather_line_points(readings, column, from:, step: WEATHER_CHART_WIDTH.to_f / days,
                                                    height_of: ->(value) { (value - low) / span * WEATHER_CHART_HEIGHT }))
    end
    alt = t('plantings.show.weather_temperature_chart_alt', low: weather_degrees(values.min), high: weather_degrees(values.max))
    weather_chart(safe_join(lines), alt, 'weather-temperature', seasons:, days:)
  end

  # The "x,y" points of one line, placed by date. `height_of` turns a value into its distance from the bottom.
  def weather_line_points(readings, column, from:, step:, height_of:)
    readings.filter_map do |reading|
      value = reading.public_send(column)
      next unless value

      "#{((reading.date - from) * step).round(1)},#{(WEATHER_CHART_HEIGHT - height_of.call(value)).round(1)}"
    end.join(' ')
  end

  # A faint band behind the chart for each season, so the weather can be read against the year.
  def weather_season_bands(seasons, days)
    step = WEATHER_CHART_WIDTH.to_f / days
    safe_join(seasons.map do |band|
      tag.rect(class: "weather-season season-#{band[:season]}", x: (band[:first] * step).round(2), y: 0,
               width: ((band[:last] - band[:first] + 1) * step).round(2), height: WEATHER_CHART_HEIGHT)
    end)
  end

  # The seasons' names, laid out under the charts to the same widths as their bands.
  def weather_season_strip(seasons, days)
    return if seasons.empty?

    tag.div(class: 'weather-seasons', aria: { hidden: true }) do
      safe_join(seasons.map do |band|
        width = ((band[:last] - band[:first] + 1) * 100.0 / days).round(2)
        tag.span(t("plantings.show.weather_season_#{band[:season]}"), class: "season-#{band[:season]}", style: "width: #{width}%")
      end)
    end
  end

  def weather_chart(content, description, css, seasons:, days:)
    tag.svg(safe_join([weather_season_bands(seasons, days), content]), class: "weather-chart #{css}",
                                                                      viewBox: "0 0 #{WEATHER_CHART_WIDTH} #{WEATHER_CHART_HEIGHT}",
                                                                      preserveAspectRatio: 'none', role: 'img', 'aria-label': description)
  end
end
