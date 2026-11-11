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
  include OpenMeteoBudget

  # name: where the gardens in the cell say they are, for the progress lines.
  Cell = Struct.new(:latitude, :longitude, :ranges, :planting_count, :name)

  # ERA5 trails real time by about five days.
  LAG_DAYS = 5
  # How far back the first fetch for a new place reaches. History fills in the rest.
  CURRENT_DAYS = 30
  CHUNK_DAYS = 366
  FIRST_DAY = Date.new(1940, 1, 1) # where ERA5 starts
  # Returns how many days of readings were saved.
  def update_all
    cells = cells_by_busiest
    say "#{cells.size} places with plantings to follow, the busiest first"
    cells.sum { |cell| fetch_current(cell) } + backfill(cells)
  end

  private

  def cells_by_busiest
    cells = plantings.group_by(&:weather_cell)
      .map { |(latitude, longitude), grouped| build_cell(latitude, longitude, grouped) }
    cells.reject { |cell| cell.ranges.empty? }.sort_by { |cell| -cell.planting_count }
  end

  # See Planting.weather_tracked. Nurseries are left out: seedlings there have no climate to show.
  def plantings
    Planting.weather_tracked(@today).includes(:garden, crop: :parent)
  end

  def build_cell(latitude, longitude, grouped)
    ranges = grouped.map { |planting| planting_range(planting) }.select { |from, to| from <= to }
    name = grouped.filter_map { |planting| planting.garden&.location.presence }.tally.max_by(&:last)&.first
    Cell.new(latitude, longitude, merge_overlapping(ranges), grouped.size, name)
  end

  def planting_range(planting)
    [[first_day(planting), FIRST_DAY].max, [planting.finished_at, @today - LAG_DAYS].compact.min]
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

  # A planting is followed from the day it was planted, but only for its last year, so a decade-old perennial costs
  # no more than one planted last year. A recent one also gets the year before it started, as below.
  def first_day(planting)
    shown_from = planting.weather_first_day(@today)
    shown_from > planting.planted_at ? shown_from : history_start(planting)
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

  # Passes over the stretches, one more year of history for each, until the budget or the history runs out.
  # A stretch that adds nothing, because it is complete, failed or the budget is spent, is left out of later passes.
  def backfill(cells)
    pending = cells.flat_map { |cell| cell.ranges.map { |range| [cell, range] } }
    saved = 0
    until pending.empty?
      pending = pending.select do |cell, range|
        added = fetch_older(cell, range)
        saved += added
        added.positive?
      end
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
    cost = OpenMeteoClient.call_cost(from, to)
    return 0 if from > to
    return out_of_budget(cell, from, to) if @calls_used + cost > @budget

    @calls_used += cost
    pause(cost)
    saved = save(cell, @client.daily(latitude: cell.latitude, longitude: cell.longitude, from:, to:))
    say "#{describe(cell)} #{from} to #{to}: #{saved} days saved (#{@calls_used.ceil} calls so far)"
    saved
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("WeatherUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    say "#{describe(cell)} #{from} to #{to}: failed, #{e.message}"
    0
  end

  def out_of_budget(cell, from, to)
    say "#{describe(cell)} #{from} to #{to}: skipped, not enough of the call budget left"
    0
  end

  def describe(cell)
    [cell.name, "#{cell.latitude}, #{cell.longitude}"].compact.join(' ')
  end

  # Wait long enough that heavy requests, a year of history being about 60 calls, stay inside the per-minute limit.
  def pause(cost)
    sleep(cost * @seconds_per_call) if @seconds_per_call.positive?
  end

  # One statement for the whole stretch. Every row needs every column, so any value Open-Meteo lacked is nil.
  def save(cell, days)
    blank = OpenMeteoClient::VARIABLES.values.index_with(nil)
    rows = days.map do |date, values|
      blank.merge(values).merge(latitude: cell.latitude, longitude: cell.longitude, date:, source: OpenMeteoClient::SOURCE)
    end
    WeatherReading.upsert_all(rows, unique_by: %i(latitude longitude date)) if rows.any? # rubocop:disable Rails/SkipsModelValidations
    rows.size
  end
end
