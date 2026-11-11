# frozen_string_literal: true

# The temperatures a crop grows best in and survives, according to EcoCrop, as bands across a planting's temperature
# chart, so the weather can be read against them.
module WeatherRangeBandsHelper
  include WeatherChartFrameHelper

  # One day's high and low.
  WeatherDay = Data.define(:date, :high, :low)

  # The icon of a climate note, by how the weather went: all good, mixed, or beyond what the crop survives on enough days.
  # :neutral is for a crop with only survivable limits to compare against.
  WEATHER_NOTE_ICONS = { success: 'check-circle', caution: 'exclamation-circle', danger: 'exclamation-triangle',
                         neutral: 'info-circle' }.freeze
  # A period is good when at least this share of its days had a high inside the best range, and none went past the range the
  # crop grows in; it is a warning when at least WEATHER_NOTE_DANGER_SHARE of its days did, and that share going too hot or
  # too cold is named in the note's title. A period within the range it grows in but short of the best is no warning: the
  # crop grows, only not as fast.
  WEATHER_NOTE_GOOD_SHARE = 0.6
  WEATHER_NOTE_DANGER_SHARE = 0.05
  # Where the band labels go, in chart units (the chart is as many pixels tall): the least distance from the top, below the
  # "Latest" label, how far under its band's top edge a label sits, and how tall one is.
  WEATHER_LABEL_TOP = 20
  WEATHER_LABEL_INSET = 2
  WEATHER_LABEL_HEIGHT = 15

  # { optimal: [low, high], absolute: [low, high], kill: degrees } for a crop, leaving out what EcoCrop has nothing on. The
  # best range needs both its ends; the absolute one can have only one, and is then open at the other. kill is the
  # temperature that kills the crop while it grows. Nil with none of them.
  def weather_temperature_ranges(crop)
    return unless crop

    # Remembered for a day, per crop and parent as they last changed, since finding the crop's EcoCrop record takes
    # queries and the ranges hardly ever change.
    Rails.cache.fetch(['weather-temperature-ranges', crop.cache_key_with_version, crop.parent&.cache_key_with_version,
                       Time.zone.today.to_s], expires_in: 1.day) { weather_ranges_of(crop.ecocrop_data) }
  end

  # Up to two notes for under a temperature chart's caption, each judging a stretch of days against the crop's ranges: how
  # the planting has gone so far (the observed readings), and how it is expected to go (`expected`, last year's weather
  # for the days still to come). A single day says little about a plant, so each is judged over all its days, by how many
  # had a high inside the best range and how many went past what the crop survives. The past is judged up to `through`, the
  # day the planting was expected to finish, since the weather after that is not what it was growing through. Nil without
  # ranges or days to judge.
  def weather_climate_notes(readings, ranges, crop:, expected: [], through: nil)
    return unless ranges

    past = through ? readings.select { |reading| reading.date <= through } : readings
    notes = { past:, future: expected }.filter_map { |period, rows| weather_period_note(period, rows, ranges, crop) }
    safe_join(notes) if notes.any?
  end

  # "12 of 20", the days with both a high and a low whose high was in the best range; nil without a best range.
  def weather_best_days(readings, ranges)
    optimal = ranges&.dig(:optimal)
    days = weather_days_of(readings)
    return unless optimal && days.any?

    t('plantings.show.weather_best_days_value', count: days.count { |day| day.high.between?(*optimal) }, total: days.size)
  end

  private

  # { optimal: [low, high], absolute: [low, high] } from an EcoCrop record, or nil without one.
  def weather_ranges_of(data)
    return unless data

    ranges = {}
    ranges[:optimal] = [data.topmn, data.topmx] if data.topmn && data.topmx
    ranges[:absolute] = [data.tmin, data.tmax] if data.tmin || data.tmax
    ranges[:kill] = data.ktmp if data.ktmp
    ranges.presence
  end

  # The days that have both a high and a low, as plain figures, so working through a year of them reads each reading's
  # attributes once.
  def weather_days_of(readings)
    readings.filter_map do |reading|
      high = reading.temp_max_c
      low = reading.temp_min_c
      WeatherDay.new(reading.date, high, low) if high && low
    end
  end

  # One note: a title for how the period went, and the figures behind it. `period` is :past or :future.
  def weather_period_note(period, rows, ranges, crop)
    days = weather_days_of(rows)
    return if days.empty?

    figures = weather_period_figures(days, ranges)
    weather_note(figures[:level], weather_period_title(period, figures, crop), weather_period_detail(period, days, ranges, figures, crop),
                 icons: (%w(skull snowflake) if figures[:killed].positive?), cold: weather_period_cold?(figures))
  end

  # Whether the cold alone was the trouble, for a note to be blue and not red: too cold with no heat, or the lows killing the
  # crop when no heat stands out.
  def weather_period_cold?(figures)
    %i(caution danger).include?(figures[:level]) && (figures[:cause] == :cold || (figures[:cause].nil? && figures[:killed].positive?))
  end

  # The title: when the weather went past the range the crop grows in and it is clear whether it was too hot, too cold or
  # both, it says so; when it stayed within that range but short of the best, it says the crop grows, not as fast; otherwise
  # how it went.
  def weather_period_title(period, figures, crop)
    key = if %i(caution danger).include?(figures[:level]) && figures[:cause] then "too_#{figures[:cause]}"
          elsif figures[:level] == :neutral && figures[:best] then 'slow'
          else figures[:level]
          end
    t("plantings.show.weather_note_#{period}_#{key}", crop: crop.name)
  end

  # How many of the days had a high inside the best range, how many went past the range the crop grows in (a high above its
  # warmest or a low below its coldest) and how many of each, and the level of the whole: :success, :caution (a few days
  # past the range), :danger (many), or :neutral when it stayed within the range but short of the best, or there is no best
  # range to compare against.
  def weather_period_figures(days, ranges)
    optimal = ranges[:optimal]
    low, high = ranges[:absolute]
    hot = high ? days.count { |day| day.high > high } : 0
    cold = low ? days.count { |day| day.low < low } : 0
    beyond = days.count { |day| (high && day.high > high) || (low && day.low < low) }
    best = optimal ? days.count { |day| day.high.between?(*optimal) } : nil
    killed = ranges[:kill] ? days.count { |day| day.low <= ranges[:kill] } : 0
    { hot:, cold:, best:, killed:, total: days.size, level: killed.positive? ? :danger : weather_period_level(days.size, beyond, best),
      cause: weather_period_cause(hot, cold, days.size), below: optimal ? days.count { |day| day.high < optimal.first } : 0,
      above: optimal ? days.count { |day| day.high > optimal.last } : 0 }
  end

  # :hot, :cold or :both when at least WEATHER_NOTE_DANGER_SHARE of the days went past the warmest the crop grows in, or the
  # coldest, and nil when neither did.
  def weather_period_cause(hot, cold, total)
    ways = { hot:, cold: }.select { |_, count| count.to_f / total >= WEATHER_NOTE_DANGER_SHARE }.keys
    ways.size == 2 ? :both : ways.first
  end

  def weather_period_level(total, beyond, best)
    return :danger if beyond.to_f / total >= WEATHER_NOTE_DANGER_SHARE
    return :caution if beyond.positive?

    best.nil? || best.to_f / total < WEATHER_NOTE_GOOD_SHARE ? :neutral : :success
  end

  # What the note says about the days: how many were in the best range, and which went too hot or too cold.
  def weather_period_detail(period, days, ranges, figures, crop)
    span = { from: l(days.first.date, format: :short), to: l(days.last.date, format: :short) }
    problems = weather_period_problems(figures, ranges[:absolute])
    sentences = []
    if ranges[:optimal]
      sentences << t("plantings.show.weather_note_#{period}_best", **span, best: figures[:best], total: figures[:total],
                                                                  range: weather_range_in_degrees(ranges[:optimal]))
    elsif problems.empty?
      sentences << t("plantings.show.weather_note_#{period}_survives", **span, crop: crop.name)
    end
    outside = weather_period_outside(figures)
    if figures[:killed].positive?
      sentences << t("plantings.show.weather_note_#{period}_killed", days: weather_days(figures[:killed]),
                                                                    limit: weather_degrees(ranges[:kill]))
    end
    sentences << t("plantings.show.weather_note_#{period}_outside", outside: outside.to_sentence) if outside.any?
    sentences << t("plantings.show.weather_note_#{period}_problems", problems: problems.to_sentence) if problems.any?
    sentences.join(' ')
  end

  # "below the best range on 20 days", for each way the days' highs missed the best range.
  def weather_period_outside(figures)
    { below: figures[:below], above: figures[:above] }.filter_map do |way, count|
      t("plantings.show.weather_note_#{way}", days: weather_days(count)) if count.positive?
    end
  end

  # "too hot on 13 days (highs above 30°C)", for each way the weather went past what the crop survives.
  def weather_period_problems(figures, absolute)
    low, high = absolute
    { hot: high, cold: low }.filter_map do |way, limit|
      next unless figures[way].positive?

      t("plantings.show.weather_note_#{way}", days: weather_days(figures[way]), limit: weather_degrees(limit))
    end
  end

  # "25 days": what the notes count.
  def weather_days(count)
    t('plantings.show.weather_days_count', count:)
  end

  def weather_range_in_degrees(range)
    "#{weather_tick(range.first, '')}–#{weather_tick(range.last, '°C')}"
  end

  # A small card: an icon for how it went, what it says, and the figures behind it.
  # `icons` replace the one the level has: a skull and a snowflake for a crop that the cold would kill.
  # `cold` makes the note blue, since red reads as too hot.
  def weather_note(level, title, detail, icons: nil, cold: false)
    icons ||= [WEATHER_NOTE_ICONS.fetch(level)]
    tag.div(class: ["weather-note weather-note--#{level}", ('weather-note--cold' if cold)], role: 'status') do
      safe_join([tag.span(safe_join(icons.map { |icon| tag.i(class: "fas fa-#{icon} weather-note-icon", aria: { hidden: true }) }),
                          class: 'weather-note-icons'),
                 tag.div(safe_join([tag.strong(title), tag.span(detail)]))])
    end
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

  # A solid line across the chart at the temperature that kills the crop while it grows, and what it is beside it.
  def weather_kill_line(ranges, scale)
    return unless ranges&.dig(:kill)

    y = weather_range_y(ranges[:kill], scale)
    tag.line(class: 'weather-kill-line', x1: 0, x2: WEATHER_CHART_WIDTH, y1: y, y2: y)
  end

  def weather_kill_label(ranges, scale)
    return unless ranges&.dig(:kill)

    y = weather_range_y(ranges[:kill], scale)
    tag.span(t('plantings.show.weather_kill_line', degrees: weather_tick(ranges[:kill], '')),
             class: 'weather-kill-label', style: "top: #{(y * 100 / WEATHER_CHART_HEIGHT).round(2)}%")
  end

  # What each band is, in the chart's right-hand corner, under its top edge. The "Latest" label owns the very top, so a
  # label never sits above WEATHER_LABEL_TOP, and the best range's label is moved down when it would land on the survivable
  # range's.
  def weather_range_labels(ranges, scale)
    return unless ranges

    below = WEATHER_LABEL_TOP
    safe_join(%i(absolute optimal).filter_map do |kind|
      next unless ranges[kind]

      wanted = weather_range_edges(ranges[kind], scale).first + WEATHER_LABEL_INSET
      y = [wanted, below].max.clamp(0, WEATHER_CHART_HEIGHT - WEATHER_LABEL_HEIGHT).to_f
      below = y + WEATHER_LABEL_HEIGHT
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
