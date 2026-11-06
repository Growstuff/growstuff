# frozen_string_literal: true

# Works out typical frost dates for each weather grid cell that has a planting growing, or finished in the
# last few weeks, and saves them as FrostYear and FrostStat rows, so a page only reads one row. Cells with
# no FrostStat yet are done first, the busiest first, as far as the call budget allows.
#
# History comes from the Open-Meteo ERA5 archive, for `temperature_2m_min` alone, which counts at the base
# rate. Dates a cell already has in WeatherReading are not fetched again. What is fetched is not saved
# as WeatherReading rows, because a row holding one figure would look complete to WeatherUpdater.
#
# Approximate, regional and for entertainment only: see docs/adr/0003-frost-dates.md.
class FrostUpdater
  # How many complete frost years of history each cell is worked out from.
  YEARS = 30
  THRESHOLDS = [FrostCalculator::FROST_C, FrostCalculator::FROST_RISK_C].freeze
  # Kept apart from WeatherUpdater's 4,500, so a day with both stays under Open-Meteo's 10,000 a day.
  DAILY_BUDGET = 4500
  SECONDS_PER_CALL = WeatherUpdater::SECONDS_PER_CALL

  Cell = Struct.new(:latitude, :longitude, :planting_count)

  attr_reader :calls_used

  def initialize(client: OpenMeteoClient.new, today: Time.zone.today, budget: DAILY_BUDGET, seconds_per_call: SECONDS_PER_CALL)
    @client = client
    @today = today
    @budget = budget
    @seconds_per_call = seconds_per_call
    @calls_used = 0
  end

  # Returns how many cells were done.
  def update_all
    cells_to_do.sum { |cell| update(cell) }
  end

  private

  def cells_to_do
    counts = Planting.weather_tracked(@today).includes(:garden).group_by { |planting| grid_point(planting.garden) }
    done = FrostStat.where(threshold_c: THRESHOLDS.first).pluck(:latitude, :longitude).to_set
    counts.except(*done)
      .map { |(latitude, longitude), plantings| Cell.new(latitude, longitude, plantings.size) }
      .sort_by { |cell| -cell.planting_count }
  end

  def grid_point(garden)
    WeatherReading.grid_point(garden.latitude, garden.longitude)
  end

  # 1 when the cell was saved, else 0. A cell that doesn't fit what is left of the budget is left for another day.
  def update(cell)
    from, to = period(cell)
    held = readings_held(cell, from, to)
    missing = (from..to).reject { |day| held.key?(day) }
    fetched = missing.empty? ? {} : fetch(cell, missing.first, missing.last)
    return 0 unless fetched

    save(cell, held.merge(fetched))
    1
  end

  # The last YEARS complete frost years. ERA5 trails real time by about five days.
  def period(cell)
    last = [@today.year, @today.year - 1].find do |year|
      FrostCalculator.frost_year_end(year, latitude: cell.latitude) <= @today - WeatherUpdater::LAG_DAYS
    end
    [FrostCalculator.frost_year_start(last - YEARS + 1, latitude: cell.latitude),
     FrostCalculator.frost_year_end(last, latitude: cell.latitude)]
  end

  def readings_held(cell, from, to)
    WeatherReading.at(cell.latitude, cell.longitude).between(from, to).where.not(temp_min_c: nil).pluck(:date, :temp_min_c).to_h
  end

  # Returns the minimums, or nil when the budget or the API says no.
  def fetch(cell, from, to)
    cost = call_cost(from, to)
    return if @calls_used + cost > @budget

    @calls_used += cost
    sleep(cost * @seconds_per_call) if @seconds_per_call.positive?
    @client.minimums(latitude: cell.latitude, longitude: cell.longitude, from:, to:)
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("FrostUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    nil
  end

  # One variable is the base rate; a request for more than two weeks counts as several calls.
  def call_cost(from, to)
    [(to - from + 1) / WeatherUpdater::DAYS_PER_CALL, 1].max
  end

  def save(cell, minimums)
    now = Time.current
    FrostStat.transaction do
      THRESHOLDS.each do |threshold|
        calculator = FrostCalculator.new(minimums, latitude: cell.latitude, threshold:)
        save_years(cell, threshold, calculator.years)
        save_stat(cell, threshold, calculator.summary, now)
      end
    end
  end

  def save_years(cell, threshold, years)
    rows = years.map do |year|
      { latitude: cell.latitude, longitude: cell.longitude, threshold_c: threshold, year: year.year,
        first_frost: year.first_frost, last_frost: year.last_frost, lowest_c: year.lowest_c }
    end
    FrostYear.upsert_all(rows, unique_by: %i(latitude longitude threshold_c year)) if rows.any? # rubocop:disable Rails/SkipsModelValidations
  end

  def save_stat(cell, threshold, summary, now)
    stat = FrostStat.find_or_initialize_by(latitude: cell.latitude, longitude: cell.longitude, threshold_c: threshold)
    stat.update!(summary.to_h.merge(computed_at: now))
  end
end
