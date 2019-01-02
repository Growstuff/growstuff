class AddPlantPartToHarvests < ActiveRecord::Migration[4.2]
  def change
    add_column :harvests, :plant_part, :string
  end
end
