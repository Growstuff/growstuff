# frozen_string_literal: true

# The temperatures a crop grows best in and survives, according to EcoCrop, as bands across a planting's temperature
# chart, so the weather can be read against them.
module WeatherRangeBandsHelper
  include WeatherChartFrameHelper

  # One day's high and low, and the average of the two.
  WeatherDay = Data.define(:date, :high, :low) do
    def mean
      (high + low) / 2.0
    end
  end

  # The icon of a climate note, by how the weather went: all good, mixed, or beyond what the crop survives on enough days.
  # :neutral is for a crop with only survivable limits to compare against.
  WEATHER_NOTE_ICONS = { success: 'check-circle', caution: 'exclamation-circle', danger: 'exclamation-triangle',
                         neutral: 'info-circle' }.freeze
  # A period is good when at least this share of its days averaged inside the best range, and none went past the survivable
  # limits; it is a warning when at least WEATHER_NOTE_DANGER_SHARE of its days did.
  WEATHER_NOTE_GOOD_SHARE = 0.6
  WEATHER_NOTE_DANGER_SHARE = 0.05
  # Where the band labels go, in chart units (the chart is as many pixels tall): the least distance from the top, below the
  # "Latest" label, how far under its band's top edge a label sits, and how tall one is.
  WEATHER_LABEL_TOP = 20
  WEATHER_LABEL_INSET = 2
  WEATHER_LABEL_HEIGHT = 15

  # { optimal: [low, high], absolute: [low, high] } for a crop, leaving out what EcoCrop has nothing on. The best range
  # needs both its ends; the absolute one can have only one, and is then open at the other. Nil with neither.
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
  # averaged inside the best range and how many went past what the crop survives. The past is judged up to `through`, the
  # day the planting was expected to finish, since the weather after that is not what it was growing through. Nil without
  # ranges or days to judge.
  def weather_climate_notes(readings, ranges, crop:, expected: [], through: nil)
    return unless ranges

    past = through ? readings.select { |reading| reading.date <= through } : readings
    notes = { past:, future: expected }.filter_map { |period, rows| weather_period_note(period, rows, ranges, crop) }
    safe_join(notes) if notes.any?
  end

  # "12 of 20", the days with both a high and a low whose average was in the best range; nil without a best range.
  def weather_best_days(readings, ranges)
    optimal = ranges&.dig(:optimal)
    days = weather_days_of(readings)
    return unless optimal && days.any?

    t('plantings.show.weather_best_days_value', count: days.count { |day| day.mean.between?(*optimal) }, total: days.size)
  end

  private

  # { optimal: [low, high], absolute: [low, high] } from an EcoCrop record, or nil without one.
  def weather_ranges_of(data)
    return unless data

    ranges = {}
    ranges[:optimal] = [data.topmn, data.topmx] if data.topmn && data.topmx
    ranges[:absolute] = [data.tmin, data.tmax] if data.tmin || data.tmax
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
    weather_note(figures[:level], t("plantings.show.weather_note_#{period}_#{figures[:level]}", crop: crop.name),
                 weather_period_detail(period, days, ranges, figures, crop))
  end

  # How many of the days averaged inside the best range, how many went past what the crop survives (a high above its
  # warmest or a low below its coldest) and how many of each, and the level of the whole: :success, :caution, :danger, or
  # :neutral when there is no best range to compare against.
  def weather_period_figures(days, ranges)
    optimal = ranges[:optimal]
    low, high = ranges[:absolute]
    hot = high ? days.count { |day| day.high > high } : 0
    cold = low ? days.count { |day| day.low < low } : 0
    beyond = days.count { |day| (high && day.high > high) || (low && day.low < low) }
    best = optimal ? days.count { |day| day.mean.between?(*optimal) } : nil
    { hot:, cold:, best:, total: days.size, level: weather_period_level(days.size, beyond, best) }
  end

  def weather_period_level(total, beyond, best)
    return :danger if beyond.to_f / total >= WEATHER_NOTE_DANGER_SHARE
    return :neutral if best.nil? && beyond.zero?
    return :success if beyond.zero? && best.to_f / total >= WEATHER_NOTE_GOOD_SHARE

    :caution
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
    sentences << t("plantings.show.weather_note_#{period}_problems", problems: problems.to_sentence) if problems.any?
    sentences.join(' ')
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
  def weather_note(level, title, detail)
    tag.div(class: "weather-note weather-note--#{level}", role: 'status') do
      safe_join([tag.i(class: "fas fa-#{WEATHER_NOTE_ICONS.fetch(level)} weather-note-icon", aria: { hidden: true }),
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
