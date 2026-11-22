# frozen_string_literal: true

# What the planting reminder email says about where a member gardens and what the weather is doing there:
# the season, the last two weeks, the next two weeks as a year ago had them, the soil temperature, a warm or cold last
# 30 days, and crops to sow. All of it hangs on the member's location, so #located? is false when they haven't given
# one. Weather is only there for places the daily update collects it for, so each part may be missing.
class PlantingReminderOutlook
  include SeasonsHelper

  DAYS = 14
  CROPS = 3
  # How many degrees warmer or colder than usual the last 30 days must be for the email to say so.
  SPELL_C = 1.0

  def initialize(member, today: Time.zone.today)
    @member = member
    @today = today
  end

  # What we've added since we last emailed them. Someone who has never had a reminder is counted from when they
  # joined, so a new member isn't told about what was there when they arrived.
  def new_features
    NewFeatures.since(@member.planting_reminder_sent_at || @member.created_at)
  end

  def located?
    @member.latitude.present? && @member.longitude.present?
  end

  def season
    season_for(@member.latitude, @today) if located?
  end

  def place
    @member.location.presence
  end

  # The weather of the last two weeks, newest day we have last. ERA5 trails real time by days, so this may be short.
  def recent
    @recent ||= readings(@today - DAYS, @today - 1)
  end

  # The next two weeks as they were a year ago, with the dates moved forward: a prediction, not a forecast.
  def expected
    @expected ||= readings(@today.prev_year, (@today + DAYS - 1).prev_year)
  end

  # The newest soil temperature we hold for the place, as a reading.
  def soil
    return unless located?

    @soil ||= cell.where.not(soil_temp_c: nil).where(date: ..@today).order(date: :desc).first
  end

  # The climate of the member's weather cell, or nil without a location or climate data for it.
  def climate
    return unless located?

    @climate = PlaceClimate.for(Place.new(@member.latitude, @member.longitude), today: @today) unless defined?(@climate)
    @climate
  end

  # Whether the average air temperature of the last 30 days is more than SPELL_C above the usual for those dates.
  def warm_spell?
    difference = climate&.air_recent_difference
    difference.present? && difference > SPELL_C
  end

  # Whether it is more than SPELL_C below.
  def cold_spell?
    difference = climate&.air_recent_difference
    difference.present? && difference < -SPELL_C
  end

  # Whether the last 30 days were warm or cold enough to say so.
  def spell?
    warm_spell? || cold_spell?
  end

  # Crops gardeners at this latitude are sowing now, leaving out what the member grows or has hidden.
  def crops
    return [] unless located?

    @crops ||= MemberDashboard.new(@member, today: @today).easy_to_sow(CROPS)
  end

  private

  def readings(from, to)
    located? ? cell.between(from, to).order(:date).to_a : []
  end

  def cell
    WeatherReading.at(*WeatherReading.grid_point(@member.latitude, @member.longitude))
  end
end
