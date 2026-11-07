# frozen_string_literal: true

# The weather a planting grew through, and is expected to: charts and figures for plantings#show.
module PlantingWeatherHelper
  include SeasonsHelper
  include WeatherChartFrameHelper

  WEATHER_MIN_BAR_WIDTH = 0.6

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

  # The frost danger figures for a planting's cell as label => text, which are the usual first and last dates, with the
  # earliest and latest likely, and the frost-free days. None for a cell with little frost, which has no dates.
  def frost_danger_figures(stat, planted_on)
    return {} unless stat.dated?

    year = FrostCalculator.frost_year_of(planted_on, latitude: stat.latitude)
    figures = {
      first: t('plantings.show.frost_danger.first_text', date:  frost_day(stat, :first_frost_median, year),
                                                         early: frost_day(stat, :first_frost_p10, year)),
      last:  t('plantings.show.frost_danger.last_text', date: frost_day(stat, :last_frost_median, year),
                                                        late: frost_day(stat, :last_frost_p90, year))
    }
    figures[:free_days] = t('plantings.show.frost_danger.days', count: stat.frost_free_days_median.round) if stat.frost_free_days_median
    figures
  end

  # Where the planting day falls against the frost danger season: before it starts, before the usual last frost danger,
  # before the safe-to-plant date, or after it. Nil for a cell with no dates.
  def frost_danger_timing(stat, planted_on)
    return unless stat.dated?

    year = FrostCalculator.frost_year_of(planted_on, latitude: stat.latitude)
    first, last, safe = %i(first_frost_p10 last_frost_median last_frost_p90).map { |field| stat.date_for(field, year) }
    key = if planted_on < first then :before_season
          elsif planted_on <= last then :before_last
          elsif planted_on <= safe then :before_safe
          else :after_safe
          end
    shown = key == :before_season ? :first_frost_p10 : :last_frost_median
    t("plantings.show.frost_danger.timing.#{key}", date: frost_day(stat, shown, year), safe: frost_day(stat, :last_frost_p90, year))
  end

  # The figures in a summary, as a phrase, leaving out any we have no data for: "7 mm of rain, highs up to 16.5°C and
  # lows down to 6.5°C". Nil when we have none of them. `weather_summary` leaves out what is missing.
  def weather_figures(summary)
    [("#{summary[:rain]} of rain" if summary[:rain]),
     ("highs up to #{summary[:hottest]}" if summary[:hottest]),
     ("lows down to #{summary[:coldest]}" if summary[:coldest])].compact.to_sentence.presence
  end

  def frost_day(stat, field, year)
    l(stat.date_for(field, year), format: '%-d %B')
  end

  # How many days the weather charts' X axis spans, from the first day of weather: the same stretch as the progress
  # bar above them, which is the crop's expected lifespan, plus the last day itself. A planting still growing past its due
  # date runs on to today, so its weather isn't cut off, and one planted over a year ago shows only its last year.
  def weather_axis_days(planting)
    [(planting.weather_axis_last_day - planting.weather_first_day).to_i, 0].max + 1
  end

  # Today, for the charts' "now" line: only while the planting is still in progress and today is on the axis.
  def weather_now(planting, days)
    today = Time.zone.today
    today if planting.growing? && !planting.failed? && today.between?(planting.weather_first_day, planting.weather_first_day + days - 1)
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

  # Daily rainfall as bars, placed by date along an axis that starts on `from` and runs for `days`.
  # `expected` is the same for days still to come: paler, because it is a prediction.
  def weather_rain_chart(readings, from:, days:, seasons: [], expected: [], now: nil, frost: nil) # rubocop:disable Metrics/ParameterLists
    top = [(readings + expected).filter_map(&:rainfall_mm).max.to_f.ceil, 1].max
    step = weather_step(days)
    bars = safe_join([weather_rain_bars(readings, from:, step:, top:),
                      weather_rain_bars(expected, from:, step:, top:, css: 'weather-expected')])
    latest = readings.last
    if latest
      label = t('plantings.show.weather_now_rain', date: l(latest.date, format: :short),
                                                   rain: "#{latest.rainfall_mm.to_f.round(1)} mm")
    end
    ticks = [[0, weather_tick(top, 'mm')], [0.5, weather_tick(top / 2.0, 'mm')], [1, weather_tick(0, 'mm')]]
    weather_chart(safe_join([weather_season_bands(seasons, days), weather_frost_bands(frost, from:, days:), bars]),
                  t('plantings.show.weather_rain_chart_alt', max: top, count: readings.size), 'weather-rain',
                  now: [weather_now_x(now, from, days), label], ticks:)
  end

  # The daily high and low as two lines, on the same axis. `expected` continues them, dashed and paler,
  # from the last observed day.
  def weather_temperature_chart(readings, from:, days:, seasons: [], expected: [], now: nil, frost: nil) # rubocop:disable Metrics/ParameterLists
    observed = weather_temperatures(readings)
    values = observed + weather_temperatures(expected)
    return if values.empty?

    low = values.min.floor
    high = [values.max.ceil, low + 1].max
    scale = { low:, span: high - low, step: weather_step(days) }
    lines = weather_temperature_lines(readings, from:, scale:)
    lines += weather_temperature_lines(readings.last(1) + expected, from:, css: 'weather-expected', scale:) if expected.any?
    range = observed.presence || values
    alt = t('plantings.show.weather_temperature_chart_alt', low: weather_degrees(range.min), high: weather_degrees(range.max))
    ticks = [[0, weather_tick(high, '°')], [0.5, weather_tick((low + high) / 2.0, '°')], [1, weather_tick(low, '°')]]
    frost_line = weather_frost_line(frost, scale, days)
    weather_chart(safe_join([weather_season_bands(seasons, days), weather_frost_bands(frost, from:, days:), frost_line, lines]),
                  alt, 'weather-temperature',
                  now: [weather_now_x(now, from, days), weather_now_temperatures(readings.last)], ticks:)
  end

  # The seasons' names, laid out under the charts to the same widths as their bands.
  def weather_season_strip(seasons, days)
    return if seasons.empty?

    tag.div(class: 'weather-seasons', aria: { hidden: true }) do
      safe_join(seasons.map do |band|
        width = ((band[:last] - band[:first] + 1) * 100.0 / days).round(2)
        tag.span(t("seasons.#{band[:season]}"), class: "season-#{band[:season]}", style: "width: #{width}%")
      end)
    end
  end

  private

  def weather_degrees(celsius)
    "#{celsius.round(1)}°C"
  end

  # Every high and low in a run of readings.
  def weather_temperatures(readings)
    readings.flat_map { |reading| [reading.temp_max_c, reading.temp_min_c] }.compact
  end

  def weather_rain_bars(readings, from:, step:, top:, css: nil)
    safe_join(readings.filter_map do |reading|
      next unless reading.rainfall_mm&.positive?

      height = (reading.rainfall_mm / top * WEATHER_CHART_HEIGHT).round(1)
      tag.rect(class: css, x: ((reading.date - from) * step).round(2), y: WEATHER_CHART_HEIGHT - height,
               width: [step, WEATHER_MIN_BAR_WIDTH].max.round(2), height:)
    end)
  end

  def weather_temperature_lines(readings, from:, scale:, css: nil)
    height_of = ->(value) { (value - scale[:low]) / scale[:span] * WEATHER_CHART_HEIGHT }
    safe_join({ 'weather-high' => :temp_max_c, 'weather-low' => :temp_min_c }.map do |line, column|
      tag.polyline(class: [line, css], points: weather_line_points(readings, column, from:, step: scale[:step], height_of:))
    end)
  end

  # The "x,y" points of one line, placed by date. `height_of` turns a value into its distance from the bottom.
  def weather_line_points(readings, column, from:, step:, height_of:)
    readings.filter_map do |reading|
      value = reading.public_send(column)
      next unless value

      "#{((reading.date - from) * step).round(1)},#{(WEATHER_CHART_HEIGHT - height_of.call(value)).round(1)}"
    end.join(' ')
  end

  # Bands behind the chart for the usual frost danger: stronger from the usual first to the usual last, paler from the
  # earliest to the latest likely. One of each for every frost year that touches the axis. None without dates.
  def weather_frost_bands(stat, from:, days:)
    return '' unless stat&.dated?

    last_day = from + days - 1
    years = (FrostCalculator.frost_year_of(from,
                                           latitude: stat.latitude) - 1)..(FrostCalculator.frost_year_of(last_day,
                                                                                                         latitude: stat.latitude) + 1)
    spans = { 'weather-frost-wide' => %i(first_frost_p10 last_frost_p90), 'weather-frost' => %i(first_frost_median last_frost_median) }
    safe_join(spans.flat_map do |css, (first, last)|
      years.filter_map do |year|
        weather_frost_band(css, stat.date_for(first, year)..stat.date_for(last, year), from:, last_day:, step: weather_step(days))
      end
    end)
  end

  def weather_frost_band(css, dates, from:, last_day:, step:)
    first = [dates.first, from].max
    last = [dates.last, last_day].min
    return if first > last

    tag.rect(class: css, x: ((first - from) * step).round(2), y: 0, width: ((last - first + 1) * step).round(2),
             height: WEATHER_CHART_HEIGHT)
  end

  # A dashed line across the temperature chart at the frost danger temperature, when the chart's range reaches it.
  def weather_frost_line(stat, scale, days)
    degrees = FrostCalculator::FROST_RISK_C
    return unless stat&.dated? && degrees.between?(scale[:low], scale[:low] + scale[:span])

    y = (WEATHER_CHART_HEIGHT - ((degrees - scale[:low]) / scale[:span] * WEATHER_CHART_HEIGHT)).round(1)
    tag.line(class: 'weather-frost-line', x1: 0, x2: (days * scale[:step]).round(2), y1: y, y2: y)
  end

  # A faint band behind the chart for each season, so the weather can be read against the year.
  def weather_season_bands(seasons, days)
    step = weather_step(days)
    safe_join(seasons.map do |band|
      tag.rect(class: "weather-season season-#{band[:season]}", x: (band[:first] * step).round(2), y: 0,
               width: ((band[:last] - band[:first] + 1) * step).round(2), height: WEATHER_CHART_HEIGHT)
    end)
  end
end
