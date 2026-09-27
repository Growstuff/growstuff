# frozen_string_literal: true

# How big a plant is drawn on a bed's layout, as a diameter in grid cells: a
# tomato might be 2, basil 0.5.
#
# A crop's default_diameter is what its plants are drawn at unless one has been
# resized; blank until someone sets it, meaning one cell. A plant's diameter is
# blank until that plant is resized, meaning it follows its crop.
class AddDiametersToCropsAndPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :crops, :default_diameter, :float
    add_column :plants, :diameter, :float
  end
end
