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
      planted_from_values: Planting::PLANTED_FROM_VALUES,
      sunniness_values:    Planting::SUNNINESS_VALUES
    }
  end

  private

  def values
    {
      id: @planting.id, url: Rails.application.routes.url_helpers.planting_path(@planting),
      crop: { id: @planting.crop_id, name: @planting.crop.name },
      planted_at: @planting.planted_at,
      planted_from: @planting.planted_from, sunniness: @planting.sunniness,
      quantity: @planting.quantity, overall_rating: @planting.overall_rating,
      description: @planting.description,
      finished: @planting.finished, finished_at: @planting.finished_at, failed: @planting.failed
    }
  end
end
