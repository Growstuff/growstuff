# frozen_string_literal: true

# Whether the climate data we hold covers the places members say they are, as ClimateCoverage does for gardens. A member
# is covered when their own location is, or any of their gardens is: climate data is fetched for gardens, so a member
# is often covered through one. Data that is only stale counts as stale, and up to date data in either place wins.
# Fuzzy on purpose: it only compares weather cells, and every garden counts, in use or not.
class MemberClimateCoverage < ClimateCoverage
  # Whether the member's own location is covered, missing or unlocated.
  def own_status(id)
    own.fetch(id)
  end

  # How many of the member's gardens have a location, how many of those are up to date and how many are stale, as
  # [located, covered, stale].
  def gardens(id)
    found = garden_statuses.fetch(id, [])
    [found.count { |status| status != UNLOCATED }, found.count(COVERED), found.count(STALE)]
  end

  private

  # { id => status }, from the member's own location and their gardens'.
  def statuses
    @statuses ||= own.to_h { |id, own_status| [id, overall(own_status, garden_statuses.fetch(id, []))] }
  end

  def overall(own_status, gardens)
    all = [own_status, *gardens]
    STATUSES.find { |status| all.include?(status) } || UNLOCATED
  end

  def own
    @own ||= @scope.pluck(:id, :latitude, :longitude).to_h { |id, latitude, longitude| [id, status(self.class.cell(latitude, longitude))] }
  end

  # { member id => the status of each of their gardens }
  def garden_statuses
    @garden_statuses ||= Garden.where(owner_id: own.keys).pluck(:owner_id, :latitude, :longitude).group_by(&:first)
      .transform_values { |rows| rows.map { |_owner, latitude, longitude| status(self.class.cell(latitude, longitude)) } }
  end
end
