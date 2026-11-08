# frozen_string_literal: true

# What a place's weather is usually like, month by month, and how this year compares, from the ClimateMonth rows of its
# weather cell. It holds the working out for the rainfall and temperature sections of a place's page, and no text.
# "Usual" is the average of the complete years we hold, about thirty. Approximate and regional.
class PlaceClimate
  # The column each measure is kept in.
  COLUMNS = { rain: :rain_mm, air: :temp_mean_c, soil: :soil_temp_c }.freeze
  # How far this year's rain, as a share of the usual, can be from the usual and still be close to it.
  RAIN_CLOSE = 0.15
  # How far this year's air temperature, in degrees, can be from the usual to be close to it, and to be a little different.
  AIR_CLOSE = 0.3
  AIR_A_LITTLE = 1.0

  # The hottest, coldest and so on, with the day: { value:, on: }.
  Record = Struct.new(:value, :on)

  # The most extreme day of the years we hold, and this year's own, as the column of the figure, the column of its date
  # and how to pick the best: Record for :hottest_day, :coldest_night, :warmest_soil or :coldest_soil.
  RECORDS = { hottest_day: %i(temp_max_c temp_max_on max_by), coldest_night: %i(temp_min_c temp_min_on min_by),
              warmest_soil: %i(soil_temp_max_c soil_temp_max_on max_by), coldest_soil: %i(soil_temp_min_c soil_temp_min_on min_by) }.freeze

  attr_reader :today

  # place: anything with a weather_cell, such as a Garden or a Place. Nil when we have no months for its cell.
  def self.for(place, today: Time.zone.today)
    return unless place.weather_located?

    months = ClimateMonth.at(*place.weather_cell).to_a
    new(months, today:) if months.any?
  end

  def initialize(months, today:)
    @today = today
    @past = months.reject { |month| month.year >= today.year }.group_by(&:month)
    @year = months.select { |month| month.year == today.year }.index_by(&:month)
  end

  # How many complete years the usual figures are from.
  def years_held
    @past.values.flatten.map(&:year).uniq.size
  end

  # Whether any of this year's weather is in.
  def this_year?
    @year.any?
  end

  # { month number => the usual figure for the month } for :rain, :air or :soil, leaving out months with none.
  def usual(measure)
    @usual ||= {}
    @usual[measure] ||= @past.transform_values { |rows| average(rows.filter_map(&COLUMNS.fetch(measure))) }.compact
  end

  # { month number => this year's figure so far } for :rain, :air or :soil. The current month is the part gone so far.
  def this_year(measure)
    @year.transform_values(&COLUMNS.fetch(measure)).compact
  end

  def usual_rain_for_year
    usual(:rain).values.sum
  end

  # This year's rain so far, and the rain that usually falls by now, over the months we have both for. The month the data
  # stops in counts for the part of it gone, in both.
  def rain_this_year
    paired(:rain).sum(&:rain_mm)
  end

  def usual_rain_to_date
    paired(:rain).sum { |row| usual(:rain)[row.month] * share_of_month(row) }
  end

  # This year's rain so far as a share of the usual by now, as a fraction, or nil with no figures.
  def rain_share
    usual_rain_to_date.positive? ? rain_this_year / usual_rain_to_date : nil
  end

  # :drier, :close or :wetter than usual, or nil.
  def rain_comparison
    return unless rain_share

    if rain_share < 1 - RAIN_CLOSE then :drier
    elsif rain_share > 1 + RAIN_CLOSE then :wetter
    else :close
    end
  end

  # The average air temperature so far this year, and what it usually is by now, each weighted by the days counted.
  def air_this_year
    weighted_air(&:temp_mean_c)
  end

  def air_usual_to_date
    weighted_air { |row| usual(:air)[row.month] }
  end

  def air_difference
    (air_this_year - air_usual_to_date).round(1) if air_this_year && air_usual_to_date
  end

  # :cooler, :a_little_cooler, :close, :a_little_warmer or :warmer than usual, or nil.
  def air_comparison
    difference = air_difference
    return unless difference

    direction = difference.negative? ? 'cooler' : 'warmer'
    if difference.abs < AIR_CLOSE then :close
    elsif difference.abs < AIR_A_LITTLE then :"a_little_#{direction}"
    else direction.to_sym
    end
  end

  # The month number with the most or least of a measure, usually, and the figure: [month, value].
  def extreme_month(measure, direction)
    usual(measure).public_send(direction == :most ? :max_by : :min_by) { |_, value| value }
  end

  def record(name)
    value, date, pick = RECORDS.fetch(name)
    best(@past.values.flatten + @year.values, value, date, pick)
  end

  def record_this_year(name)
    value, date, pick = RECORDS.fetch(name)
    best(@year.values, value, date, pick)
  end

  private

  def average(values)
    (values.sum / values.size).round(1) if values.any?
  end

  # How much of its month a row's days are: 1 for a whole month.
  def share_of_month(row)
    row.days.fdiv(Time.days_in_month(row.month, row.year))
  end

  # This year's months that have a figure for the measure and a usual one to set it against.
  def paired(measure)
    @year.values.select { |row| row[COLUMNS.fetch(measure)] && usual(measure)[row.month] }
  end

  def weighted_air
    rows = paired(:air)
    days = rows.sum(&:days)
    (rows.sum { |row| yield(row) * row.days } / days).round(1) if days.positive?
  end

  def best(rows, value, date, pick)
    row = rows.select(&value).public_send(pick, &value)
    Record.new(row[value], row[date]) if row
  end
end
