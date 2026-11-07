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
    finished_clear: :check, finished_hit: :warning, finished_undated: :clock, rare: :sun
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
    { title: t("#{scope}.#{far ? 'title_far' : 'title'}", crop: frost.crop_name), body: frost_verdict_body(frost, scope, key) }
  end

  # The figures under the timeline: { label:, value:, note: }. A planting that has finished has no frost-free season.
  def frost_cards(frost)
    return [frost_coldest_card(frost), frost_in_danger_card(frost), frost_last_card(frost)].compact if frost.finished?

    [frost_coldest_card(frost), frost_last_card(frost), frost_next_card(frost), frost_free_card(frost)].compact
  end

  # How the planting date sits against the usual last frost.
  def frost_planted_sentence(frost)
    count = frost.planted_days_before_usual_end
    key = "#{frost.from_nursery? ? 'planted_out' : 'planted'}.#{count.negative? ? 'after' : 'before'}"
    dates = { planted: frost.planted_on, usual_end: frost.usual.last }.transform_values { |date| frost_date_text(date) }
    t("plantings.frost.#{key}", crop: frost.crop_name, days: frost_days(count.abs), **dates)
  end

  def frost_date_text(date)
    l(date, format: '%-d %b')
  end

  def frost_days(count)
    t('plantings.frost.days', count:)
  end

  private

  def frost_degrees(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def frost_verdict_body(frost, scope, key)
    suffix = '_no_readings' if key == :finished_clear && frost.coldest_night_c.nil?
    days = FROST_VERDICT_DAYS[key]
    args = { crop: frost.crop_name, count: frost.frost_nights, days: (frost_days(frost.public_send(days)) if days),
             coldest: frost_degrees(frost.coldest_night_c), threshold: frost_degrees(PlantingFrost::THRESHOLD_C) }
    dates = { usual_start: frost.usual.first, usual_end: frost.usual.last, earliest: frost.possible.first, latest: frost.possible.last }
    body = t("#{scope}.body#{suffix}", **args, **dates.transform_values { |date| frost_date_text(date) })
    planted = frost_planted_sentence(frost) if %i(passed finished_clear finished_undated).include?(key) && !frost.long_lived?
    nights = t('plantings.frost.nights_so_far', **args.slice(:count, :coldest, :threshold)) if frost_hit_so_far?(frost)
    [body, planted, nights].compact.join(' ')
  end

  # A planting still growing that frost danger has reached, which the sentence about the season doesn't say.
  def frost_hit_so_far?(frost)
    !frost.finished? && frost.frost_nights.positive?
  end

  # The coldest night the planting had, with how it sits against the frost danger line, in words.
  def frost_coldest_card(frost)
    return unless frost.margin_c

    gap = frost.margin_c
    key = %w(note_below note_at note_above)[(gap <=> 0) + 1]
    note = t("plantings.frost.cards.coldest.#{key}", gap: frost_degrees(gap.abs), threshold: frost_degrees(PlantingFrost::THRESHOLD_C))
    value = t('plantings.frost.degrees', degrees: frost_degrees(frost.coldest_night_c))
    { label: t('plantings.frost.cards.coldest.label'), value:, note: }
  end

  def frost_in_danger_card(frost)
    return if frost.end_unknown?

    { label: t('plantings.frost.cards.in_danger.label'), value: frost_days(frost.days_in_danger),
      note: t('plantings.frost.cards.in_danger.note', latest: frost_date_text(frost.possible.last)) }
  end

  def frost_last_card(frost)
    note = if frost.finished? && !frost.long_lived?
             frost_planted_note(frost)
           else
             t('plantings.frost.cards.last.note', latest: frost_date_text(frost.possible.last))
           end
    { label: t('plantings.frost.cards.last.label'), value: frost_date_text(frost.usual.last), note: }
  end

  def frost_planted_note(frost)
    count = frost.planted_days_before_usual_end
    key = "planted#{'_out' if frost.from_nursery?}_#{count.negative? ? 'after' : 'before'}"
    t("plantings.frost.cards.last.#{key}", days: frost_days(count.abs))
  end

  def frost_next_card(frost)
    key = frost.end_ahead? ? 'note_finishes' : 'note_now'
    note = t("plantings.frost.cards.next.#{key}", crop: frost.crop_name, earliest: frost_date_text(frost.next_season_earliest),
                                                  days:     frost_days(frost.days_to_next_season))
    { label: t('plantings.frost.cards.next.label'), value: frost_date_text(frost.next_season_start), note: }
  end

  def frost_free_card(frost)
    return unless frost.frost_free_days

    { label: t('plantings.frost.cards.free.label'), value: frost_days(frost.frost_free_days), note: t('plantings.frost.cards.free.note') }
  end
end
