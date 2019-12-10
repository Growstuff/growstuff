class AddHarvestCountToCrop < ActiveRecord::Migration[5.2]
  def change
    add_column :crops, :harvests_count, :integer
    add_column :crops, :photo_associations_count, :integer
    add_column :plant_parts, :harvests_count, :integer

    Crop.all.each do |crop|
      Crop.reset_counters(crop.id, :harvests)
      Crop.reset_counters(crop.id, :photos)
      say "Crop #{crop.name} counter caches updated"
    end
    PlantPart.all.each do |pp|
      PlantPart.reset_counters(pp.id, :harvests)
      say "PlantPart #{pp.name} counter caches updated"
    end
  end
end
