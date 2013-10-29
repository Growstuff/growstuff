class AddPlantPartToHarvests < ActiveRecord::Migration
  def change
    add_column :harvests, :plant_part, :string
  end
end
