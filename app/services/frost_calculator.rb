# frozen_string_literal: true

# Turns a place's daily minimum temperatures into typical first and last frost dates. See FrostYear for what a
# frost year is. Dates in a summary are counted as days into the frost year, so they sort and average sensibly.
# The last frost of year N pairs with the first frost of year N + 1 to make the frost-free stretch between them.
# Leap days can shift a count by one day, which is well inside the uncertainty.
#
# Approximate, regional and for entertainment only: see docs/adr/0003-frost-dates.md.
class FrostCalculator
  # At or below this, in degrees Celsius, a day counts as frost. Kept here so it can change without a migration.
  FROST_C = 0.0
  # The lighter threshold members see as "frost danger".
  FROST_DANGER_C = 2.0

  # Years with frost: at least this share is `frost`, at least RARE_BELOW is `possible`, fewer is `rare`.
  COMMON_FROM = 0.7
  RARE_BELOW = 0.3

  # Day numbers are days into the frost year, starting at 0. The dates are nil for `rare` and `unknown`.
  Summary = Struct.new(:status, :years_used, :frost_years, :first_frost_median, :first_frost_p10,
                       :last_frost_median, :last_frost_p90, :frost_free_days_median, keyword_init: true)

  # readings: { Date => minimum temperature in degrees C }
  # max_missing_days: how many days a year may lack a reading and still be used. Model data has none
  # missing; weather stations often do. A missing day is treated as not frosty.
  def initialize(readings, latitude:, threshold: FROST_C, max_missing_days: 0)
    @readings = readings
    @latitude = latitude
    @threshold = threshold
    @max_missing_days = max_missing_days
  end

  # An unsaved FrostYear for each year with (nearly) every day, so a partial year can't hide a frost.
  def years
    @years ||= year_numbers.filter_map { |year| frost_year(year) }
  end

  def summary
    frosty = years.select(&:frost?)
    status = status_for(years.empty? ? nil : frosty.size.fdiv(years.size))
    return Summary.new(status:, years_used: years.size, frost_years: frosty.size) if %i(unknown rare).include?(status)

    firsts, lasts = %i(first_frost last_frost).map { |field| frosty.map { |year| days_into(year, field) } }
    Summary.new(status:, years_used: years.size, frost_years: frosty.size,
                first_frost_median: percentile(firsts, 50), first_frost_p10: percentile(firsts, 10),
                last_frost_median: percentile(lasts, 50), last_frost_p90: percentile(lasts, 90),
                frost_free_days_median: (median_frost_free_days if status == :frost))
  end

  private

  def status_for(share)
    if share.nil? then :unknown
    elsif share >= COMMON_FROM then :frost
    elsif share >= RARE_BELOW then :possible
    else :rare
    end
  end

  # Days from the last frost of one year to the first frost of the next, where both years had frost.
  def median_frost_free_days
    by_year = years.index_by(&:year)
    spans = by_year.filter_map do |year, result|
      following = by_year[year + 1]
      (following.first_frost - result.last_frost).to_i if result.frost? && following&.frost?
    end
    percentile(spans, 50) if spans.any?
  end

  def days_into(frost_year, field)
    (frost_year[field] - FrostYear.start_of(frost_year.year, latitude: @latitude)).to_i
  end

  def year_numbers
    @readings.keys.map { |date| FrostYear.containing(date, latitude: @latitude) }.uniq.sort
  end

  def frost_year(year)
    days = FrostYear.start_of(year, latitude: @latitude)..FrostYear.end_of(year, latitude: @latitude)
    temps = days.index_with { |day| @readings[day] }.compact
    return if temps.size < days.count - @max_missing_days

    frosts = temps.select { |_day, temp| temp <= @threshold }.keys
    FrostYear.new(year:, first_frost: frosts.first, last_frost: frosts.last, lowest_c: temps.values.min)
  end

  # Linear-interpolated percentile (0..100) of a list of numbers.
  def percentile(values, percent)
    sorted = values.sort
    rank = (percent / 100.0) * (sorted.size - 1)
    low = sorted[rank.floor]
    low + ((sorted[rank.ceil] - low) * (rank - rank.floor))
  end
end
