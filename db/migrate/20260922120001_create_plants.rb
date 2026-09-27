# frozen_string_literal: true

# One row per individual plant in a planting, so a planting of ten tomatoes is
# ten plants that can be placed on the bed's layout grid one at a time.
#
# A plant with no bed_x/bed_y has not been placed yet. Giving each plant its own
# record also leaves somewhere to hang per-plant state later, such as one plant
# failing while the rest of the planting carries on.
class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants do |t|
      t.references :planting, null: false, foreign_key: true, index: false
      # Where the plant sits on the bed, as its centre in grid cells: 2.5, 1.5
      # is the middle of the third cell along and the second down. Fractional,
      # because a plant can sit anywhere on the bed rather than only in a cell.
      t.float :bed_x
      t.float :bed_y

      t.timestamps
    end

    add_index :plants, %i(planting_id bed_x bed_y)
  end
end
