# frozen_string_literal: true

# What a place's weather is usually like in each of the four seasons, from the ClimateMonth rows of its weather cell: the
# average temperature, how cold the nights and how hot the days usually get, and the rain. Seasons are the grower's own
# (see SeasonsHelper), in the order they are lived, starting at spring. It holds the working out and no text.
#
# "Usual" is the average of the complete years we hold, about thirty, as in PlaceClimate. Approximate and regional.
class SeasonalClimate
  include SeasonsHelper

  # name: :spring, :summer, :autumn or :winter. months: their numbers. mean: the average air temperature, in °C.
  # night: how cold the nights fall in a typical month of the season, and day: how hot the days get, both in °C. rain: the
  # season's rain in mm. Each figure is nil when we hold nothing for the season. current: whether it is the season now.
  Season = Data.define(:name, :months, :mean, :night, :day, :rain, :current)

  # The member's weather cell, from the place on their profile. Nil without a location, or with no weather held for it yet.
  def self.for(member, today: Time.zone.today)
    return unless member.latitude.present? && member.longitude.present?

    months = ClimateMonth.at(*Place.new(member.latitude, member.longitude).weather_cell).to_a
    new(months, latitude: member.latitude, today:) if months.any?
  end

  def initialize(months, latitude:, today:)
    @past = months.reject { |month| month.year >= today.year }.group_by(&:month)
    @half = hemisphere(latitude)
    @current = season_in(@half, today)
  end

  # How many complete years the figures are from.
  def years
    @past.values.flatten.map(&:year).uniq.size
  end

  # The four seasons, as Season, in the order the grower lives them.
  def seasons
    SEASON_MONTHS.fetch(@half).map { |name, months| season(name, months) }
  end

  private

  def season(name, months)
    rows = months.flat_map { |month| @past.fetch(month, []) }
    Season.new(name:, months:, mean: average(rows.filter_map(&:temp_mean_c)), night: average(rows.filter_map(&:temp_min_c)),
               day: average(rows.filter_map(&:temp_max_c)), rain: rain(months), current: name == @current)
  end

  # The usual rain of each month of the season, added up, for the months we hold any.
  def rain(months)
    usual = months.filter_map { |month| average(@past.fetch(month, []).filter_map(&:rain_mm)) }
    usual.sum if usual.any?
  end

  def average(values)
    values.sum / values.size if values.any?
  end
end
