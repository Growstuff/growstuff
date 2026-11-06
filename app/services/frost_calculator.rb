# frozen_string_literal: true

# Turns a place's daily minimum temperatures into typical first and last frost dates.
#
# A frost year is the stretch of twelve months that holds one winter whole: the calendar year in the
# Southern Hemisphere, July to June in the Northern. Dates are counted as days into the frost year
# so they sort and average sensibly. The year is named for the calendar year it ends in, which for the
# frost-free stretch means the last frost of year N always pairs with the first frost of year N + 1.
# Leap days can shift a count by one day, which is well inside the uncertainty.
#
# Approximate, regional and for entertainment only: see docs/frost-dates-plan.md.
class FrostCalculator
  # At or below this, in degrees Celsius, a day counts as frost. Kept here so it can change without a migration.
  FROST_C = 0.0
  # The lighter "frost risk" threshold.
  FROST_RISK_C = 2.0

  # Years with frost: at least this share is `frost`, at least RARE_BELOW is `possible`, fewer is `rare`.
  COMMON_FROM = 0.7
  RARE_BELOW = 0.3

  YearResult = Struct.new(:year, :first_frost, :last_frost, :lowest_c) do
    def frost?
      !first_frost.nil?
    end
  end

  # Day numbers are days into the frost year, starting at 0. Percentile fields are nil for `rare`.
  Summary = Struct.new(:status, :years_used, :frost_years, :first_frost_median, :first_frost_p10,
                       :last_frost_median, :last_frost_p90, :frost_free_days_median, keyword_init: true)

  # readings: { Date => minimum temperature in degrees C }
  # max_missing_days: how many days a year may lack a reading and still be used. Model data has none
  # missing; weather stations often do. A missing day is treated as not frosty.
  def initialize(readings, latitude:, threshold: FROST_C, max_missing_days: 0)
    @readings = readings
    @max_missing_days = max_missing_days
    @southern = latitude.negative?
    @threshold = threshold
  end

  # Only years with (nearly) every day are used, so a partial year can't hide a frost.
  def years
    @years ||= candidate_years.filter_map { |year| year_result(year) }
  end

  def summary
    return Summary.new(status: :unknown, years_used: 0, frost_years: 0) if years.empty?

    with_frost = years.select(&:frost?)
    status = status_for(with_frost.size.fdiv(years.size))
    return Summary.new(status:, years_used: years.size, frost_years: with_frost.size) if status == :rare

    build_summary(status, with_frost)
  end

  # The calendar date a day number falls on in a given frost year.
  def date_for(day, year)
    frost_year_start(year) + day.round
  end

  def frost_year_start(year)
    @southern ? Date.new(year, 1, 1) : Date.new(year - 1, 7, 1)
  end

  # Linear-interpolated percentile (0..100) of a list of numbers.
  def self.percentile(values, percent)
    sorted = values.sort
    return sorted.first.to_f if sorted.one?

    rank = (percent / 100.0) * (sorted.size - 1)
    low = sorted[rank.floor]
    high = sorted[rank.ceil]
    low + ((high - low) * (rank - rank.floor))
  end

  private

  def build_summary(status, with_frost)
    firsts = with_frost.map { |year| offset(year.first_frost, year.year) }
    lasts = with_frost.map { |year| offset(year.last_frost, year.year) }
    Summary.new(status:, years_used: years.size, frost_years: with_frost.size,
                first_frost_median: self.class.percentile(firsts, 50), first_frost_p10: self.class.percentile(firsts, 10),
                last_frost_median: self.class.percentile(lasts, 50), last_frost_p90: self.class.percentile(lasts, 90),
                frost_free_days_median: (median_frost_free_days if status == :frost))
  end

  def status_for(share)
    if share >= COMMON_FROM then :frost
    elsif share >= RARE_BELOW then :possible
    else :rare
    end
  end

  # Days from the last frost of one year to the first frost of the next, where both years had frost.
  def median_frost_free_days
    by_year = years.index_by(&:year)
    spans = by_year.filter_map do |year, result|
      following = by_year[year + 1]
      next unless result.frost? && following&.frost?

      (following.first_frost - result.last_frost).to_i
    end
    spans.empty? ? nil : self.class.percentile(spans, 50)
  end

  def offset(date, year)
    (date - frost_year_start(year)).to_i
  end

  def candidate_years
    dates = @readings.keys
    return [] if dates.empty?

    dates.map { |date| frost_year_of(date) }.uniq.sort
  end

  def frost_year_of(date)
    @southern || date.month < 7 ? date.year : date.year + 1
  end

  def year_result(year)
    start = frost_year_start(year)
    days = (start...(start >> 12)).to_a
    known = days.select { |day| @readings[day] }
    return if known.size < days.size - @max_missing_days

    frosts = known.select { |day| @readings[day] <= @threshold }
    YearResult.new(year, frosts.first, frosts.last, known.map { |day| @readings[day] }.min)
  end
end
