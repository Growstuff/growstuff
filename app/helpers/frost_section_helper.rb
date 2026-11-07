# frozen_string_literal: true

# What the frost section of a planting page says and draws, from a PlantingFrost. The working out is in PlantingFrost
# and the words are in the locale files; this puts the two together.
module FrostSectionHelper
  # Outline icons, 24 by 24, one for each verdict.
  FROST_ICONS = {
    snow:    'M12 2v20M4.2 7l15.6 10M4.2 17L19.8 7',
    warning: 'M12 3L2.5 20h19L12 3zM12 10v4M12 17v.5',
    clock:   'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 7v5l3 2',
    check:   'M5 12.5l4.5 4.5L19 7.5',
    sun:     'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4' \
             'M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4'
  }.freeze
  FROST_VERDICT_ICONS = {
    before_season: :snow, in_season: :warning, late_possible: :clock, passed: :check,
    finished_clear: :check, finished_hit: :warning, rare: :sun
  }.freeze
  # Which count of days each verdict's sentence is about.
  FROST_VERDICT_DAYS = {
    before_season: :days_until_usual_start, in_season: :days_until_usual_end,
    late_possible: :days_until_latest, passed: :days_since_latest
  }.freeze

  def frost_icon(verdict)
    path = tag.path(d: FROST_ICONS.fetch(FROST_VERDICT_ICONS.fetch(verdict)))
    tag.svg(path, width: 24, height: 24, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2.5,
                  'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': true)
  end

  # The banner's headline and sentence: { title:, body: }.
  def frost_verdict(frost)
    key = frost.verdict
    scope = "plantings.frost.verdicts.#{key}"
    return { title: t("#{scope}.title"), body: t("#{scope}.body") } if key == :rare

    far = key == :before_season && !frost.starts_soon?
    { title: t("#{scope}.#{far ? 'title_far' : 'title'}"), body: frost_verdict_body(frost, scope, key) }
  end

  # The figures under the timeline: { label:, value:, note: }. A planting that has finished has no frost-free season.
  def frost_cards(frost)
    cards = [frost_margin_card(frost), (frost_in_danger_card(frost) if frost.finished?), frost_last_card(frost), frost_next_card(frost)]
    cards << frost_free_card(frost) unless frost.finished?
    cards.compact
  end

  # A band of the timeline, placed along it. The frost danger that is only possible has no label.
  def frost_band_tag(frost, band)
    label = frost_band_label(frost, band) unless band.kind == :possible
    style = "left: #{frost_percent(frost.position(band.from))}; width: #{frost_percent(frost.width(band))}"
    tag.div(label && tag.span(label, class: 'frost-band-label'), class: "frost-band frost-band--#{band.kind}", style:)
  end

  # The marker for today, and a line down through both rows, for a planting still growing.
  def frost_today_tags(frost)
    return unless frost.show_today?

    style = "left: #{frost_percent(frost.position(frost.today))}"
    pill = tag.span(t('plantings.frost.timeline.today', date: frost_date_text(frost.today)), class: 'frost-today', style:)
    safe_join([pill, tag.div(class: 'frost-today-line', style:)])
  end

  # The month starts along the axis, with the year where it starts a year or the axis. They shrink to initials on a phone.
  def frost_axis_tags(frost)
    ticks = frost.axis.select { |date| date.day == 1 }.map do |date|
      name = l(date, format: '%b')
      year = tag.span(date.year, class: 'frost-year') if date.month == 1 || date == frost.axis.first
      parts = [tag.span(name, class: 'frost-month-long'), tag.span(name.first, class: 'frost-month-short'), year]
      tag.div(safe_join(parts), class: 'frost-tick', style: "left: #{frost_percent(frost.position(date))}")
    end
    safe_join(ticks)
  end

  def frost_percent(fraction)
    "#{(fraction * 100).round(3)}%"
  end

  # The timeline in words, for a screen reader.
  def frost_timeline_description(frost)
    dates = { usual_start: frost.usual.first, usual_end: frost.usual.last, earliest: frost.possible.first, latest: frost.possible.last,
              planted: frost.planted_on, ends: frost.ends_on }.transform_values { |date| frost_date_text(date) }
    t('plantings.frost.timeline.description', from: frost_month_year(frost.axis.first), to: frost_month_year(frost.axis.last), **dates)
  end

  # The label on a band of the timeline.
  def frost_band_label(frost, band)
    case band.kind
    when :usual then frost_usual_label(frost, band)
    when :so_far then t('plantings.frost.timeline.planted', date: frost_date_text(frost.planted_on))
    when :still_to_come then t('plantings.frost.timeline.finish_expected', date: frost_date_text(frost.ends_on))
    when :finished then t('plantings.frost.timeline.finished', date: frost_date_text(frost.ends_on))
    end
  end

  # How the planting date sits against the usual last frost.
  def frost_planted_sentence(frost)
    count = frost.planted_days_before_usual_end
    key = count.negative? ? 'after' : 'before'
    t("plantings.frost.planted.#{key}", planted: frost_date_text(frost.planted_on), days: frost_days(count.abs),
                                        usual_end: frost_date_text(frost.usual.last))
  end

  def frost_date_text(date)
    l(date, format: '%-d %b')
  end

  def frost_days(count)
    t('plantings.frost.days', count:)
  end

  private

  def frost_month_year(date)
    l(date, format: '%B %Y')
  end

  def frost_degrees(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def frost_usual_label(frost, band)
    from = frost_date_text(band.from)
    return t('plantings.frost.timeline.usual_open', from:) if band.to == frost.axis.last && band.to < frost.usual.last

    t('plantings.frost.timeline.usual', from:, to: frost_date_text(band.to))
  end

  def frost_verdict_body(frost, scope, key)
    suffix = '_no_readings' if key == :finished_clear && frost.coldest_night_c.nil?
    days = FROST_VERDICT_DAYS[key]
    args = { count: frost.frost_nights, days: (frost_days(frost.public_send(days)) if days), coldest: frost_degrees(frost.coldest_night_c),
             threshold: frost_degrees(PlantingFrost::THRESHOLD_C) }
    dates = { usual_start: frost.usual.first, usual_end: frost.usual.last, earliest: frost.possible.first, latest: frost.possible.last }
    body = t("#{scope}.body#{suffix}", **args, **dates.transform_values { |date| frost_date_text(date) })
    %i(passed finished_clear).include?(key) ? "#{body} #{frost_planted_sentence(frost)}" : body
  end

  def frost_margin_card(frost)
    return unless frost.margin_c

    note = t('plantings.frost.cards.margin.note', coldest: frost_degrees(frost.coldest_night_c), threshold: frost_degrees(PlantingFrost::THRESHOLD_C))
    { label: t('plantings.frost.cards.margin.label'), value: t('plantings.frost.degrees', degrees: frost_degrees(frost.margin_c)), note: }
  end

  def frost_in_danger_card(frost)
    { label: t('plantings.frost.cards.in_danger.label'), value: frost_days(frost.days_in_danger),
      note: t('plantings.frost.cards.in_danger.note', latest: frost_date_text(frost.possible.last)) }
  end

  def frost_last_card(frost)
    note = frost.finished? ? frost_planted_note(frost) : t('plantings.frost.cards.last.note', latest: frost_date_text(frost.possible.last))
    { label: t('plantings.frost.cards.last.label'), value: frost_date_text(frost.usual.last), note: }
  end

  def frost_planted_note(frost)
    count = frost.planted_days_before_usual_end
    t("plantings.frost.cards.last.planted_#{count.negative? ? 'after' : 'before'}", days: frost_days(count.abs))
  end

  def frost_next_card(frost)
    key = frost.finished? ? 'note_finished' : 'note_finishes'
    note = t("plantings.frost.cards.next.#{key}", earliest: frost_date_text(frost.next_season_earliest),
                                                  days:     frost_days(frost.days_to_next_season))
    { label: t('plantings.frost.cards.next.label'), value: frost_date_text(frost.next_season_start), note: }
  end

  def frost_free_card(frost)
    return unless frost.frost_free_days

    { label: t('plantings.frost.cards.free.label'), value: frost_days(frost.frost_free_days), note: t('plantings.frost.cards.free.note') }
  end
end
