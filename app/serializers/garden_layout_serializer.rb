# frozen_string_literal: true

# What the GardenLayout island needs to draw a bed: the size of its grid, the
# plantings growing in it, and each planting's individual plants — the ones
# already placed on the grid and the ones still waiting to go on it.
#
# Only current plantings appear. A finished planting keeps its plants and their
# positions, but it is not drawn, so the map shows what is growing now.
class GardenLayoutSerializer
  # editable: may arrange plants (owner and collaborators).
  # resizable: may change the bed's size, which edits the garden (owner only).
  def initialize(garden, editable:, resizable: false)
    @garden = garden
    @editable = editable
    @resizable = resizable
  end

  def as_json(*)
    {
      garden:         garden_json,
      editable:       @editable,
      resizable:      @resizable,
      # Planting is a change to the garden, like resizing it, and only into an
      # active one, as with the garden page's own button.
      plantable:      @resizable && @garden.active,
      layout_url:     routes.layout_member_garden_path(@garden.owner, @garden, format: :json),
      spade_icon_url: ActionController::Base.helpers.image_path('spade-marker.svg'),
      save_url:       routes.update_layout_member_garden_path(@garden.owner, @garden),
      max_grid_size:  Garden::MAX_GRID_SIZE,
      plantings:      plantings.map { |planting| planting_json(planting) }
    }
  end

  private

  def plantings
    @plantings ||= @garden.plantings.current.includes(:plants, :crop).order(:planted_at)
  end

  def routes
    Rails.application.routes.url_helpers
  end

  def garden_json
    {
      id:           @garden.id,
      name:         @garden.name,
      url:          routes.garden_path(@garden),
      edit_url:     routes.edit_garden_path(@garden),
      grid_columns: @garden.grid_columns,
      grid_rows:    @garden.grid_rows
    }
  end

  def planting_json(planting)
    crop = planting.crop
    {
      id:        planting.id,
      url:       routes.planting_path(planting),
      crop_name: crop.name,
      # crops#show serves the crop's icon as SVG, falling back to its parent's
      # and then to a generic sprout, so every crop has one to draw.
      icon_url:  routes.crop_path(crop, format: 'svg'),
      quantity:  planting.quantity,
      # Every plant, placed or not; the island draws a circle for each.
      plants:    planting.plants.sort_by(&:id).map { |plant| plant_json(plant) }
    }
  end

  def plant_json(plant)
    { id: plant.id, bed_x: plant.bed_x, bed_y: plant.bed_y }
  end
end
