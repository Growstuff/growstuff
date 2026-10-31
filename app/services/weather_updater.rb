# frozen_string_literal: true

# Keeps WeatherReading topped up for every place that has an active planting, so a planting
# can show the weather it grew through. One request per grid cell, however many gardens and
# plantings share it.
#
# Current weather comes first, for every cell. Whatever is left of the day's call budget then
# goes on history, a year at a time, working backwards from the oldest day we hold. Most
# plantings are under a year old, so a cell finishes its history in a run or two.
class WeatherUpdater
  Cell = Struct.new(:latitude, :longitude, :from, :to, :plantings)

  # ERA5 trails real time by about five days.
  LAG_DAYS = 5
  # Only the first year of a planting's life, so a decade-old planting nobody finished costs no more.
  MAX_PLANTING_DAYS = 366
  # How far back the first fetch for a new place reaches. History fills in the rest.
  CURRENT_DAYS = 30
  CHUNK_DAYS = 366
  FIRST_DAY = Date.new(1940, 1, 1) # where ERA5 starts
  # Open-Meteo's free tier allows 10,000 calls a day; leave room for retries and by-hand runs.
  DAILY_BUDGET = 8000

  attr_reader :calls_used

  def initialize(client: OpenMeteoClient.new, today: Time.zone.today, budget: DAILY_BUDGET, delay: 0.2)
    @client = client
    @today = today
    @budget = budget
    @delay = delay
    @calls_used = 0
  end

  # Returns how many days of readings were saved.
  def update_all
    cells = cells_by_busiest
    cells.sum { |cell| fetch_current(cell) } + backfill(cells)
  end

  private

  def cells_by_busiest
    cells = Planting.active.joins(:garden).merge(Garden.where.not(latitude: nil).where.not(longitude: nil))
      .where(planted_at: ..@today).includes(:garden)
      .group_by { |planting| WeatherReading.grid_point(planting.garden.latitude, planting.garden.longitude) }
      .map { |(latitude, longitude), plantings| build_cell(latitude, longitude, plantings) }
    cells.sort_by { |cell| -cell.plantings }
  end

  def build_cell(latitude, longitude, plantings)
    latest_available = @today - LAG_DAYS
    ranges = plantings.map do |planting|
      [planting.planted_at, [planting.finished_at, planting.planted_at + MAX_PLANTING_DAYS, latest_available].compact.min]
    end
    Cell.new(latitude, longitude, [ranges.map(&:first).min, FIRST_DAY].max, ranges.map(&:last).max, plantings.size)
  end

  def fetch_current(cell)
    latest = readings(cell).maximum(:date)
    fetch(cell, latest ? latest + 1 : [cell.from, cell.to - CURRENT_DAYS + 1].max, cell.to)
  end

  # Passes over the cells, one more year of history each, until the budget or the history runs out.
  def backfill(cells)
    saved = 0
    loop do
      added = cells.sum { |cell| fetch_older(cell) }
      saved += added
      break if added.zero?
    end
    saved
  end

  def fetch_older(cell)
    earliest = readings(cell).minimum(:date)
    return 0 unless earliest && earliest > cell.from

    fetch(cell, [cell.from, earliest - CHUNK_DAYS].max, earliest - 1)
  end

  def readings(cell)
    WeatherReading.at(cell.latitude, cell.longitude)
  end

  def fetch(cell, from, to)
    cost = call_cost(from, to)
    return 0 if from > to || @calls_used + cost > @budget

    @calls_used += cost
    sleep(@delay) if @delay.positive?
    save(cell, @client.daily(latitude: cell.latitude, longitude: cell.longitude, from:, to:))
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("WeatherUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    0
  end

  # Open-Meteo counts a request for more than 10 variables, or more than 2 weeks, as several calls.
  def call_cost(from, to)
    [(to - from + 1) / 14.0, 1].max * [OpenMeteoClient::VARIABLES.size / 10.0, 1].max
  end

  def save(cell, days)
    days.each do |date, values|
      WeatherReading.find_or_initialize_by(latitude: cell.latitude, longitude: cell.longitude, date:)
        .update!(values.merge(source: OpenMeteoClient::SOURCE))
    end.size
  end
end
