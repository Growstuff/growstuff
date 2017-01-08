class AddPlantingRefToHarvests < ActiveRecord::Migration
  def change
    add_reference :harvests, :planting, index: true, foreign_key: true
  end
end
