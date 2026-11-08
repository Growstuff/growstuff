# frozen_string_literal: true

# Works out the climate of each weather grid cell that has a planting growing, or finished in the last few weeks, or a
# garden in use: its typical frost dates, as FrostYear and FrostStat rows, and its months of weather, as ClimateMonth rows,
# so a page only reads a few rows. Cells whose latest months are a week old are brought up to date, and cells with none yet
# are done, as far as the call budget allows. Cells of members who signed in or signed up lately come first, the most
# recent first, and the cells of members who haven't are left until every active member's cell is up to date.
#
# History comes from the Open-Meteo ERA5 archive, for the rain and the air and soil temperatures, which is five variables
# and so counts at the base rate, the same as one variable. Frost and the months are worked out from the same days, so a
# cell costs one request. What is fetched is not saved as WeatherReading rows, because a row holding five figures would look
# complete to WeatherUpdater.
#
# Approximate, regional and for entertainment only: see docs/adr/0003-frost-dates.md.
class ClimateUpdater
  # How many complete frost years of history each cell is worked out from.
  YEARS = 30
  THRESHOLDS = [FrostCalculator::FROST_C, FrostCalculator::FROST_DANGER_C].freeze
  VARIABLES = %w(rain_sum temperature_2m_mean temperature_2m_max temperature_2m_min soil_temperature_0_to_7cm_mean).freeze
  # Kept apart from WeatherUpdater's 4,500, so a day with both stays under Open-Meteo's 10,000 a day.
  DAILY_BUDGET = 4500
  SECONDS_PER_CALL = WeatherUpdater::SECONDS_PER_CALL
  # A cell's latest months are fetched again once they are this old, from this many whole months back.
  STALE_DAYS = 7
  REFRESH_MONTHS = 3
  # A member who has not signed in, or signed up, for this long is not active.
  ACTIVE_DAYS = 90

  # last_active_at: the latest sign in or sign up of the members whose places are in the cell, or nil.
  Cell = Struct.new(:latitude, :longitude, :place_count, :last_active_at)

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
    work.count { |step, cell| send(step, cell) }
  end

  private

  # The cells to bring up to date and to do, as [:refresh or :update, cell], in the order to try them: active members'
  # cells before the rest, refreshing before doing, then the most recently active, then the busiest.
  def work
    refreshing = cells_to_refresh.map { |cell| [:refresh, cell] }
    doing = cells_to_do.map { |cell| [:update, cell] }
    (refreshing + doing).sort_by do |step, cell|
      [active?(cell) ? 0 : 1, step == :refresh ? 0 : 1, -cell.last_active_at.to_f, -cell.place_count]
    end
  end

  def active?(cell)
    cell.last_active_at.present? && cell.last_active_at.to_date >= @today - ACTIVE_DAYS
  end

  def places
    @places ||= Planting.weather_tracked(@today).includes(:garden).to_a + Garden.active.located_for_weather.to_a
  end

  # The cells of the places, with how many places are in each and when its members were last active.
  def cells
    @cells ||= places.group_by(&:weather_cell).map do |(latitude, longitude), grouped|
      Cell.new(latitude, longitude, grouped.size, grouped.filter_map { |place| activity[place.owner_id] }.max)
    end
  end

  # { member id => when they last signed in, or signed up if they never have }, for the members of the places. Deactivated
  # members have none.
  def activity
    members = Member.kept.where(id: places.map(&:owner_id).uniq)
    @activity ||= members.pluck(:id, :last_sign_in_at, :created_at).to_h { |id, signed_in, created| [id, [signed_in, created].compact.max] }
  end

  def cells_to_do
    held = ClimateMonth.distinct.pluck(:latitude, :longitude)
    cells.reject { |cell| held.include?([cell.latitude, cell.longitude]) }
  end

  def cells_to_refresh
    stale = ClimateMonth.group(:latitude, :longitude).having('MAX(updated_at) < ?', @today - STALE_DAYS).pluck(:latitude, :longitude)
    cells.select { |cell| stale.include?([cell.latitude, cell.longitude]) }
  end

  # Saves the cell and returns truthy, or returns nil when the budget or the API says no, to be tried another day.
  def update(cell)
    daily = fetch(cell, history_from(cell), last_day)
    save(cell, daily) if daily
  end

  # Brings the latest months up to date, from the start of a month so each month is whole.
  def refresh(cell)
    from = (last_day.beginning_of_month << (REFRESH_MONTHS - 1))
    daily = fetch(cell, from, last_day)
    return unless daily

    ClimateMonth.transaction do
      ClimateMonth.at(cell.latitude, cell.longitude).where('make_date(year, month, 1) >= ?', from).delete_all
      save_months(cell, daily)
    end
  end

  # ERA5 trails real time by about five days.
  def last_day
    @today - WeatherUpdater::LAG_DAYS
  end

  # The start of the last YEARS complete frost years.
  def history_from(cell)
    last = [@today.year, @today.year - 1].find { |year| FrostYear.end_of(year, latitude: cell.latitude) <= last_day }
    FrostYear.start_of(last - YEARS + 1, latitude: cell.latitude)
  end

  # The days from the API, or nil when it doesn't fit what is left of the budget or the API fails.
  def fetch(cell, from, to)
    cost = OpenMeteoClient.call_cost(from, to, variables: VARIABLES.size)
    return if @calls_used + cost > @budget

    @calls_used += cost
    sleep(cost * @seconds_per_call) if @seconds_per_call.positive?
    @client.daily(latitude: cell.latitude, longitude: cell.longitude, from:, to:, variables: VARIABLES)
  rescue OpenMeteoClient::Error => e
    Rails.logger.warn("ClimateUpdater: #{cell.latitude},#{cell.longitude}: #{e.message}")
    nil
  end

  def save(cell, daily)
    ActiveRecord::Base.transaction do
      save_frost(cell, daily.transform_values { |day| day[:temp_min_c] }.compact)
      ClimateMonth.at(cell.latitude, cell.longitude).delete_all
      save_months(cell, daily)
    end
  end

  def save_months(cell, daily)
    ClimateSummary.new(daily).months.each do |month|
      month.update!(latitude: cell.latitude, longitude: cell.longitude)
    end
  end

  def save_frost(cell, minimums)
    at_cell = { latitude: cell.latitude, longitude: cell.longitude }
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
