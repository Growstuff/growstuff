# frozen_string_literal: true

# What the React record-harvest dialog needs to fill in its form: the crop and
# planting it is for, sensible starting values, and the choices for its selects.
# Served by GET /plantings/:slug/harvests/new.json.
class HarvestFormSerializer
  def initialize(harvest)
    @harvest = harvest
  end

  def as_json(*)
    {
      crop:          { id: @harvest.crop_id, name: @harvest.crop.name },
      planting_id:   @harvest.planting_id,
      harvested_at:  @harvest.harvested_at,
      plant_part_id: default_plant_part_id,
      plant_parts:   PlantPart.order(:name).map { |part| { id: part.id, name: part.name } },
      units:         choices(Harvest::UNITS_VALUES),
      weight_units:  choices(Harvest::WEIGHT_UNITS_VALUES)
    }
  end

  private

  def choices(values)
    values.map { |label, value| { label: label, value: value } }
  end

  # What this crop is most often harvested for, so the common case is one less
  # thing to pick.
  def default_plant_part_id
    @harvest.crop.popular_plant_parts.keys.first&.first
  end
end
