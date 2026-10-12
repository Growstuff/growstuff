# frozen_string_literal: true

# Which months make up which season, for the grower's own hemisphere.
#
# A three-month season is a rough carve-up rather than an astronomical one, but
# it is what gardeners mean by "spring" and it lines up with the harvest-month
# data we hold.
module SeasonsHelper
  SEASON_MONTHS = {
    northern: { spring: [3, 4, 5], summer: [6, 7, 8], autumn: [9, 10, 11], winter: [12, 1, 2] },
    southern: { spring: [9, 10, 11], summer: [12, 1, 2], autumn: [3, 4, 5], winter: [6, 7, 8] }
  }.freeze

  # Nil when we don't know where they are, in which case we say nothing about
  # seasons rather than guessing at the wrong half of the world.
  def hemisphere(latitude)
    return if latitude.blank?

    latitude.to_f.negative? ? :southern : :northern
  end

  # Seasons in the order the grower lives them, starting at spring, so each
  # season is three months together rather than winter being split across the
  # ends of a January-to-December row.
  def seasons_with_months(latitude)
    half = hemisphere(latitude)
    SEASON_MONTHS[half] if half
  end

  # The season a date falls in for someone at this latitude, or nil when we
  # don't know which hemisphere they are in.
  def season_for(latitude, date = Date.current)
    seasons_with_months(latitude)&.find { |_season, months| months.include?(date.month) }&.first
  end

  # "Spring in Wellington · October · 41°S", leaving out whatever we don't know.
  def season_summary(member, date = Date.current)
    return if member.latitude.blank?

    season = season_for(member.latitude, date)
    place = member.location.presence
    degrees = "#{member.latitude.to_f.abs.round}°#{member.latitude.to_f.negative? ? 'S' : 'N'}"
    [[season&.to_s&.capitalize, place].compact.join(' in '), I18n.l(date, format: '%B'), degrees].compact_blank.join(' · ')
  end
end
