class PlantPart < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  has_many :harvests
  has_many :crops, -> { uniq }, through: :harvests

  def to_s
    name
  end

  # Postgres complains if the ORDER BY clause of a SELECT DISTINCT query is
  # not precisely one of the SELECTed fields. The default sort order on
  # crops is lower(name), and Postgres is not smart enough to notice that it
  # can calculate this from fields which are selected. The solution is to
  # override PlantParts#crops to remove the ORDER BY clause, and replace it
  # with `ORDER BY name`. This is not perfect, because it means the crops
  # associated to plant parts will not be sorted in the same order as crops
  # on the rest of the site.
  def crops
    super.reorder('name')
  end
end
