class AddHarvestCountToCrop < ActiveRecord::Migration[5.2]
  def change
    add_column :crops, :harvests_count, :integer
    add_column :plant_parts, :harvests_count, :integer
  end
end
