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
  # Open-Meteo's free tier allows 10,000 calls a day, 5,000 an hour and 600 a minute. A run, once a day, stays
  # under the hourly limit, which leaves room for retries and by-hand runs.
  DAILY_BUDGET = 4500
  # 600 calls a minute is a tenth of a second per call.
  SECONDS_PER_CALL = 0.1

  attr_reader :calls_used

  def initialize(client: OpenMeteoClient.new, today: Time.zone.today, budget: DAILY_BUDGET, seconds_per_call: SECONDS_PER_CALL)
    @client = client
    @today = today
    @budget = budget
    @seconds_per_call = seconds_per_call
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
      [history_start(planting), [planting.finished_at, planting.planted_at + MAX_PLANTING_DAYS, latest_available].compact.min]
    end
    Cell.new(latitude, longitude, [ranges.map(&:first).min, FIRST_DAY].max, ranges.map(&:last).max, plantings.size)
  end

  # A planting still growing is shown the rest of its life as last year's weather for the same days,
  # so we also want the year before it started.
  def history_start(planting)
    planting.finished? ? planting.planted_at : planting.planted_at.prev_year
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
    pause(cost)
    save(cell, @client.daily(latitude: cell.latitude, longitude: cell.longitude, from:, to:))
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("WeatherUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    0
  end

  # Wait long enough that heavy requests, a year of history being about 60 calls, stay inside the per-minute limit.
  def pause(cost)
    sleep(cost * @seconds_per_call) if @seconds_per_call.positive?
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
