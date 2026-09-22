# frozen_string_literal: true

# An individual plant within a planting: one of the ten tomatoes, rather than
# the planting of ten. It exists so each one can be placed on its garden's
# layout grid separately, and so per-plant state (one of them failing, say) has
# somewhere to live later.
#
# bed_x and bed_y are both nil until the plant is placed on the grid.
class Plant < ApplicationRecord
  belongs_to :planting

  delegate :garden, :crop, :owner, to: :planting

  scope :placed, -> { where.not(bed_x: nil).where.not(bed_y: nil) }
  scope :unplaced, -> { where(bed_x: nil).or(where(bed_y: nil)) }
  scope :outside_grid, lambda { |columns, rows|
    where('plants.bed_x > ? OR plants.bed_y > ?', columns, rows)
  }

  validates :bed_x, :bed_y, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  validate :position_must_be_complete
  validate :position_must_fit_the_grid
  validate :planting_must_have_room, on: :create

  def placed?
    bed_x.present? && bed_y.present?
  end

  private

  # A plant is either on the grid or off it: half a coordinate means the caller
  # has lost track of which.
  def position_must_be_complete
    return if bed_x.blank? == bed_y.blank?

    errors.add(:bed_x, :bed_position_incomplete)
  end

  # The position is the plant's centre, so the whole width of the bed is fair
  # game: a plant on the far edge is at grid_columns, not grid_columns - 1.
  def position_must_fit_the_grid
    return if !placed? || garden.blank?
    return if bed_x <= garden.grid_columns && bed_y <= garden.grid_rows

    errors.add(:bed_x, :bed_position_off_grid)
  end

  # Dragging off a stack makes plants one at a time, so the cap has to hold here
  # rather than only where a quantity is set.
  def planting_must_have_room
    return if planting.blank?
    return if planting.plants.count < Planting::MAX_PLANTS

    errors.add(:base, :too_many_plants, limit: Planting::MAX_PLANTS)
  end
end
