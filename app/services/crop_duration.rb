# frozen_string_literal: true

# How many days a crop takes from sowing to a first harvest, from the best figure we hold for it. In order:
#   :degree_days the crop's growing degree days, added up month by month from the weather of the gardener's place, so it
#                varies with where they garden. Needs a figure for the crop and weather for the place.
#   :ecocrop     the growing cycle EcoCrop gives, the same anywhere
#   :median      the median days members' plantings of the crop have taken to a first harvest
# A figure of zero is missing data, as EcoCrop has some. It holds the working out and no text.
class CropDuration
  # quick and slow are days; they are the same for the figures that give one number.
  Result = Data.define(:quick, :slow, :source)

  DAYS_IN_MONTH = 30.4
  # The lowest temperature a crop grows at when EcoCrop doesn't say, as growers usually take it.
  DEFAULT_BASE = 10.0
  MAX_MONTHS = 24

  # The durations for a crop at a place. record is the crop's EcoCrop record, if it is not the one the crop finds itself.
  def self.for(crop, climate, record: crop.ecocrop_data)
    new(highs: climate&.monthly_days, lows: climate&.monthly_nights, degree_days: crop.growing_degree_days_figure,
        base: record&.tmin, quick: record&.gmin, slow: record&.gmax, median: crop.median_days_to_first_harvest)
  end

  # highs and lows: { month number => the usual high or low in °C }, nil when the place is not known.
  def initialize(highs: nil, lows: nil, degree_days: nil, base: nil, quick: nil, slow: nil, median: nil)
    @highs = highs
    @lows = lows
    @degree_days = degree_days&.positive? ? degree_days : nil
    @base = base || DEFAULT_BASE
    @quick = quick&.positive? ? quick : nil
    @slow = slow&.positive? ? slow : nil
    @median = median&.positive? ? median : nil
  end

  # The Result for a crop sown in the month (1 to 12), or nil when we have no way to tell.
  def from(month)
    from_degree_days(month) || from_ecocrop || from_median
  end

  private

  # Walks the months from the sowing, each giving its usual heat, until the crop has had what it needs. Nil when a month has
  # no weather, or the heat is never had in two years.
  def from_degree_days(month)
    return unless @degree_days && @highs && @lows

    total = 0.0
    MAX_MONTHS.times do |elapsed|
      heat = month_heat(((month - 1 + elapsed) % 12) + 1)
      return nil unless heat

      return days_result(((elapsed + ((@degree_days - total) / heat)) * DAYS_IN_MONTH).round) if total + heat >= @degree_days

      total += heat
    end
    nil
  end

  # The heat of a usual month, or nil when we hold no weather for it.
  def month_heat(month)
    high = @highs[month]
    low = @lows[month]
    [((high + low) / 2.0) - @base, 0].max * DAYS_IN_MONTH if high && low
  end

  def days_result(days)
    Result.new(quick: days, slow: days, source: :degree_days)
  end

  def from_ecocrop
    Result.new(quick: @quick, slow: @slow || @quick, source: :ecocrop) if @quick
  end

  def from_median
    Result.new(quick: @median, slow: @median, source: :median) if @median
  end
end
