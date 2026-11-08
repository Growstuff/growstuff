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

  def frost_planting?(frost)
    frost.is_a?(PlantingFrost)
  end

  # The crop's name for the words about a planting, and nothing for a place alone.
  def frost_crop(frost)
    frost.crop_name if frost_planting?(frost)
  end

  # The banner's headline and sentence: { title:, body: }.
  def frost_verdict(frost)
    key = frost.verdict
    scope = "frost.verdicts.#{key}"
    return { title: t("#{scope}.title"), body: t("#{scope}.body") } if key == :rare

    { title: t("#{scope}.#{frost_title_key(frost, key)}", crop: frost_crop(frost)), body: frost_verdict_body(frost, scope, key) }
  end

  # How the planting date sits against the usual last frost.
  def frost_planted_sentence(frost)
    key = "planted#{frost_out(frost)}.#{frost_direction(frost)}"
    dates = { planted: frost.planted_on, usual_end: frost.usual.last }.transform_values { |date| frost_date_text(date) }
    t("frost.#{key}", crop: frost.crop_name, days: frost_planted_days(frost), **dates)
  end

  # Whether the planting went in after or before the usual last frost.
  def frost_direction(frost)
    frost.planted_days_before_usual_end.negative? ? 'after' : 'before'
  end

  # How many days the planting went in after or before the usual last frost, as words.
  def frost_planted_days(frost)
    frost_days(frost.planted_days_before_usual_end.abs)
  end

  # The part of a key for the words about a planting that began somewhere safe from frost, which say it went outdoors.
  def frost_out(frost)
    '_out' if frost.from_frost_safe?
  end

  def frost_date_text(date)
    l(date, format: '%-d %b')
  end

  def frost_days(count)
    t('frost.days', count:)
  end

  def frost_degrees(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  private

  # The usual and the possible dates of the season, as text for a sentence.
  def frost_season_dates(frost)
    { usual_start: frost.usual.first, usual_end: frost.usual.last, earliest: frost.possible.first, latest: frost.possible.last }
      .transform_values { |date| frost_date_text(date) }
  end

  # The title that fits: one for a verdict that is still far off, and one for a place rather than a planting.
  def frost_title_key(frost, key)
    if key == :before_season && !frost.starts_soon? then 'title_far'
    elsif key == :passed && !frost_planting?(frost) then 'title_place'
    else 'title'
    end
  end

  def frost_verdict_body(frost, scope, key)
    suffix = '_no_readings' if key == :finished_clear && frost.coldest_night_c.nil?
    days = FROST_VERDICT_DAYS[key]
    planting = frost_planting?(frost)
    args = { crop: frost_crop(frost), count: (frost.frost_nights if planting), days: (frost_days(frost.public_send(days)) if days),
             coldest: (frost_degrees(frost.coldest_night_c) if planting), threshold: frost_degrees(FrostSeason::THRESHOLD_C) }
    body = t("#{scope}.body#{suffix}", **args, **frost_season_dates(frost))
    return body unless planting

    planted = frost_planted_sentence(frost) if %i(passed finished_clear finished_undated).include?(key) && !frost.long_lived?
    nights = t('frost.nights_so_far', **args.slice(:count, :coldest, :threshold)) if frost_hit_so_far?(frost)
    [body, planted, nights].compact.join(' ')
  end

  # A planting still growing that frost danger has reached, which the sentence about the season doesn't say.
  def frost_hit_so_far?(frost)
    !frost.finished? && frost.frost_nights.positive?
  end
end
