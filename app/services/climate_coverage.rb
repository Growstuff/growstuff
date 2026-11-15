# frozen_string_literal: true

# Whether the climate data we hold covers the places of a set of members or gardens. A record is covered when its weather
# cell has ClimateMonth rows, which is what ClimateUpdater saves and a page reads. The cell comes from WeatherReading.grid_point,
# the same as everywhere else, so this agrees with what a page would show. Data not fetched for ClimateUpdater::STALE_DAYS is
# stale: the updater only refreshes cells that still have a garden or planting, so a cell nobody uses goes on getting older.
class ClimateCoverage
  COVERED = 'covered'
  STALE = 'stale'
  MISSING = 'missing'
  UNLOCATED = 'unlocated'
  STATUSES = [COVERED, STALE, MISSING, UNLOCATED].freeze

  # scope: members or gardens, anything with latitude and longitude.
  def initialize(scope, now: Time.current)
    @scope = scope
    @now = now
  end

  # How many records are in each status.
  def counts
    STATUSES.index_with { |status| statuses.count { |_id, found| found == status } }
  end

  # The ids of the records in a status.
  def ids(status)
    statuses.select { |_id, found| found == status }.keys
  end

  # The status of the record with this id, which must be in the scope.
  def status_of(id)
    statuses.fetch(id)
  end

  # The date the data for a place was last fetched, or nil when we hold none.
  def fetched_on(latitude, longitude)
    cell = self.class.cell(latitude, longitude)
    held[cell]&.to_date if cell
  end

  # The weather cell of a record, as [latitude, longitude], or nil when it has no coordinates.
  def self.cell(latitude, longitude)
    WeatherReading.grid_point(latitude, longitude) if latitude && longitude
  end

  private

  # { id => status }
  def statuses
    @statuses ||= @scope.pluck(:id, :latitude, :longitude).to_h do |id, latitude, longitude|
      [id, status(self.class.cell(latitude, longitude))]
    end
  end

  def status(cell)
    return UNLOCATED unless cell

    fetched = held[cell]
    return MISSING unless fetched

    fetched >= @now - ClimateUpdater::STALE_DAYS.days ? COVERED : STALE
  end

  # { [latitude, longitude] => when the cell's months were last saved }
  def held
    @held ||= ClimateMonth.group(:latitude, :longitude).maximum(:updated_at)
  end
end
