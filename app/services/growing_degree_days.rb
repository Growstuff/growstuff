# frozen_string_literal: true

# Warmth measured the way growers do, in growing degree days: each day counts how far its average
# temperature is above the base, below which a crop barely grows. A crop reaches harvest after roughly
# the same heat wherever it grows, even when that takes fifty days in summer and ninety in autumn.
class GrowingDegreeDays
  def initialize(base:)
    @base = base
  end

  # One day's heat, from a reading's high and low. Nothing when it is colder than the base,
  # or when the reading has no temperatures.
  def for_day(reading)
    return 0 unless reading.temp_max_c && reading.temp_min_c

    [((reading.temp_max_c + reading.temp_min_c) / 2.0) - @base, 0].max
  end

  # The heat of all these readings added together.
  def total(readings)
    readings.sum { |reading| for_day(reading) }
  end

  # The day the heat of these readings, in date order, adds up to the target, or nil if it never does.
  def date_reaching(target, readings)
    total = 0
    readings.each do |reading|
      total += for_day(reading)
      return reading.date if total >= target
    end
    nil
  end
end
