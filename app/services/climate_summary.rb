# frozen_string_literal: true

# Turns a place's daily weather into one row for each month: the rain, the average air and soil temperatures, and the
# hottest and coldest days with the dates they fell on. Months with no days are left out. It has no database or network
# use, so it is tested on fixed series.
#
# Approximate and regional: the figures come from a model of about 25 km.
class ClimateSummary
  # What a day holds: rainfall_mm, temp_mean_c, temp_max_c, temp_min_c and soil_temp_c, as OpenMeteoClient#daily gives them.
  # readings: { Date => { column => number } }
  def initialize(readings)
    @readings = readings
  end

  # An unsaved ClimateMonth for each month with any day, oldest first, without the cell.
  def months
    @readings.group_by { |date, _| [date.year, date.month] }.sort.map do |(year, month), days|
      ClimateMonth.new(year:, month:, days: days.size, **figures(days.sort.to_h))
    end
  end

  private

  def figures(days)
    {
      rain_mm: sum(days, :rainfall_mm), temp_mean_c: average(days, :temp_mean_c), soil_temp_c: average(days, :soil_temp_c),
      **extreme(days, :temp_max_c, :max, :temp_max_c, :temp_max_on), **extreme(days, :temp_min_c, :min, :temp_min_c, :temp_min_on),
      **extreme(days, :soil_temp_c, :max, :soil_temp_max_c, :soil_temp_max_on),
      **extreme(days, :soil_temp_c, :min, :soil_temp_min_c, :soil_temp_min_on)
    }
  end

  def values(days, column)
    days.values.filter_map { |day| day[column] }
  end

  def sum(days, column)
    found = values(days, column)
    found.sum.round(1) if found.any?
  end

  def average(days, column)
    found = values(days, column)
    (found.sum / found.size).round(1) if found.any?
  end

  # The day with the highest or lowest figure, as { value_column => figure, date_column => date }. The first such day wins a tie.
  def extreme(days, column, direction, value_column, date_column)
    dated = days.filter_map { |date, day| [date, day[column]] if day[column] }
    return {} if dated.empty?

    date, value = dated.public_send(direction == :max ? :max_by : :min_by) { |_, figure| figure }
    { value_column => value, date_column => date }
  end
end
