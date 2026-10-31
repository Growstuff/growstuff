# frozen_string_literal: true

# Keeps WeatherReading topped up for every place that has a planting growing, or finished in the last
# few weeks, so a planting can show the weather it grew through. One request per grid cell and stretch
# of dates, however many gardens and plantings share it.
#
# Current weather comes first, for every cell. Whatever is left of the run's call budget then goes on
# history, a year at a time, working backwards. Each planting contributes its own stretch of dates and
# only stretches that overlap are joined, so an old planting and a new one in the same cell don't pay
# for the years between them.
class WeatherUpdater
  Cell = Struct.new(:latitude, :longitude, :ranges, :plantings)

  # ERA5 trails real time by about five days.
  LAG_DAYS = 5
  # Only the first year of a planting's life, so a decade-old planting nobody finished costs no more.
  MAX_PLANTING_DAYS = 366
  # How far back the first fetch for a new place reaches. History fills in the rest.
  CURRENT_DAYS = 30
  CHUNK_DAYS = 366
  # A planting that has finished is kept until its last days, which lag, have been collected.
  RECENT_FINISH_DAYS = 30
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
    cells = plantings.group_by { |planting| WeatherReading.grid_point(planting.garden.latitude, planting.garden.longitude) }
      .map { |(latitude, longitude), grouped| build_cell(latitude, longitude, grouped) }
    cells.reject { |cell| cell.ranges.empty? }.sort_by { |cell| -cell.plantings }
  end

  # Plantings growing, or finished recently enough that their last days may not be in yet, in gardens with a location.
  # Nurseries are left out: seedlings there have no climate to show.
  def plantings
    Planting.where.not(failed: true).where(planted_at: ..@today)
      .where('plantings.finished IS NOT TRUE OR plantings.finished_at >= ?', @today - RECENT_FINISH_DAYS)
      .joins(:garden).merge(Garden.where.not(latitude: nil).where.not(longitude: nil).where(nursery: false))
      .includes(:garden, crop: :parent)
  end

  def build_cell(latitude, longitude, grouped)
    ranges = grouped.map { |planting| planting_range(planting) }.select { |from, to| from <= to }
    Cell.new(latitude, longitude, merge_overlapping(ranges), grouped.size)
  end

  def planting_range(planting)
    [[history_start(planting), FIRST_DAY].max, [planting.finished_at, last_day(planting), @today - LAG_DAYS].compact.min]
  end

  # Joins stretches of dates that overlap or touch, and leaves the rest apart.
  def merge_overlapping(ranges)
    ranges.sort.each_with_object([]) do |range, merged|
      if merged.any? && range.first <= merged.last.last + 1
        merged.last[1] = [merged.last.last, range.last].max
      else
        merged << range.dup
      end
    end
  end

  # A planting is shown no further than its due date, or a year if we don't know when that is.
  def last_day(planting)
    planting.planted_at + [planting.expected_lifespan&.to_i, MAX_PLANTING_DAYS].compact.min
  end

  # A planting still growing is shown the rest of its life as last year's weather for the same days,
  # so we also want the year before it started.
  def history_start(planting)
    planting.finished? ? planting.planted_at : planting.planted_at.prev_year
  end

  # Forward to the end of each stretch from the newest day we hold, so a planting that has just finished gets its
  # last days. A live stretch we hold nothing for starts with the last month; an old one waits for history.
  def fetch_current(cell)
    cell.ranges.sum do |from, to|
      latest = readings(cell).between(from, to).maximum(:date)
      if latest
        fetch(cell, latest + 1, to)
      elsif to >= @today - LAG_DAYS
        fetch(cell, [from, to - CURRENT_DAYS + 1].max, to)
      else
        0
      end
    end
  end

  # Passes over the cells, one more year of history for each stretch, until the budget or the history runs out.
  def backfill(cells)
    saved = 0
    loop do
      added = cells.sum { |cell| cell.ranges.sum { |range| fetch_older(cell, range) } }
      saved += added
      break if added.zero?
    end
    saved
  end

  # The year before the oldest day we hold in this stretch, or its last year when we hold nothing yet.
  def fetch_older(cell, range)
    from, to = range
    earliest = readings(cell).between(from, to).minimum(:date)
    newest_missing = earliest ? earliest - 1 : to
    return 0 if newest_missing < from

    fetch(cell, [from, newest_missing - CHUNK_DAYS + 1].max, newest_missing)
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
