# frozen_string_literal: true

# What the React edit-planting dialog needs to fill in its form: the planting's
# current values, and the choices for its selects. Served by
# GET /plantings/:slug/edit.json.
class PlantingFormSerializer
  def initialize(planting)
    @planting = planting
  end

  def as_json(*)
    {
      planting:            values,
      gardens:             gardens.map { |garden| { id: garden.id, name: garden.name } },
      planted_from_values: Planting::PLANTED_FROM_VALUES,
      sunniness_values:    Planting::SUNNINESS_VALUES
    }
  end

  private

  def values
    {
      id: @planting.id, url: Rails.application.routes.url_helpers.planting_path(@planting),
      crop: { id: @planting.crop_id, name: @planting.crop.name },
      garden_id: @planting.garden_id, planted_at: @planting.planted_at,
      planted_from: @planting.planted_from, sunniness: @planting.sunniness,
      quantity: @planting.quantity, overall_rating: @planting.overall_rating,
      description: @planting.description,
      finished: @planting.finished, finished_at: @planting.finished_at, failed: @planting.failed
    }
  end

  # The owner's active gardens, as the existing form offers, plus the one the
  # planting is in now even if it has since been marked inactive.
  def gardens
    active = @planting.owner.gardens.active.order_by_name.to_a
    active.include?(@planting.garden) ? active : [@planting.garden] + active
  end
end
