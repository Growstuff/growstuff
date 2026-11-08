# frozen_string_literal: true

# Works out typical frost dates for each weather grid cell that has a planting growing, or finished in the
# last few weeks, or a garden in use, and saves them as FrostYear and FrostStat rows, so a page only reads one row.
# Cells with no FrostStat yet are done first, the busiest first, as far as the call budget allows.
#
# History comes from the Open-Meteo ERA5 archive, for `temperature_2m_min` alone, which counts at the base
# rate. Dates a cell already has in WeatherReading are not fetched again. What is fetched is not saved
# as WeatherReading rows, because a row holding one figure would look complete to WeatherUpdater.
#
# Approximate, regional and for entertainment only: see docs/adr/0003-frost-dates.md.
class FrostUpdater
  # How many complete frost years of history each cell is worked out from.
  YEARS = 30
  THRESHOLDS = [FrostCalculator::FROST_C, FrostCalculator::FROST_DANGER_C].freeze
  # Kept apart from WeatherUpdater's 4,500, so a day with both stays under Open-Meteo's 10,000 a day.
  DAILY_BUDGET = 4500
  SECONDS_PER_CALL = WeatherUpdater::SECONDS_PER_CALL

  # place_count: how many plantings and gardens are in the cell, to do the busiest first.
  Cell = Struct.new(:latitude, :longitude, :place_count)

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
    cells_to_do.count { |cell| update(cell) }
  end

  private

  def cells_to_do
    done = FrostStat.where(threshold_c: THRESHOLDS.first).pluck(:latitude, :longitude)
    places = Planting.weather_tracked(@today).includes(:garden).to_a + Garden.active.located_for_weather.to_a
    cells = places.group_by(&:weather_cell).except(*done)
    cells.map { |(latitude, longitude), grouped| Cell.new(latitude, longitude, grouped.size) }.sort_by { |cell| -cell.place_count }
  end

  # Saves the cell and returns truthy, or returns nil when the budget or the API says no, to be tried another day.
  def update(cell)
    from, to = period(cell)
    held = WeatherReading.at(cell.latitude, cell.longitude).between(from, to).where.not(temp_min_c: nil).pluck(:date, :temp_min_c).to_h
    missing = (from..to).reject { |day| held.key?(day) }
    fetched = missing.empty? ? {} : fetch(cell, missing.first, missing.last)
    save(cell, held.merge(fetched)) if fetched
  end

  # The last YEARS complete frost years. ERA5 trails real time by about five days.
  def period(cell)
    last = [@today.year, @today.year - 1].find do |year|
      FrostYear.end_of(year, latitude: cell.latitude) <= @today - WeatherUpdater::LAG_DAYS
    end
    [FrostYear.start_of(last - YEARS + 1, latitude: cell.latitude), FrostYear.end_of(last, latitude: cell.latitude)]
  end

  # The minimums for those dates, or nil when it doesn't fit what is left of the budget or the API fails.
  def fetch(cell, from, to)
    cost = OpenMeteoClient.call_cost(from, to, variables: 1)
    return if @calls_used + cost > @budget

    @calls_used += cost
    sleep(cost * @seconds_per_call) if @seconds_per_call.positive?
    @client.minimums(latitude: cell.latitude, longitude: cell.longitude, from:, to:)
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("FrostUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    nil
  end

  def save(cell, minimums)
    at_cell = { latitude: cell.latitude, longitude: cell.longitude }
    FrostStat.transaction do
      THRESHOLDS.each do |threshold|
        calculator = FrostCalculator.new(minimums, latitude: cell.latitude, threshold:)
        rows = calculator.years.map do |year|
          year.attributes.symbolize_keys.slice(:year, :first_frost, :last_frost, :lowest_c).merge(at_cell, threshold_c: threshold)
        end
        FrostYear.upsert_all(rows, unique_by: %i(latitude longitude threshold_c year)) if rows.any? # rubocop:disable Rails/SkipsModelValidations
        FrostStat.find_or_initialize_by(**at_cell, threshold_c: threshold).update!(calculator.summary.to_h.merge(computed_at: Time.current))
      end
    end
  end
end
