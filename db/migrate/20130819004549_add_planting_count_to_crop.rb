class AddPlantingCountToCrop < ActiveRecord::Migration
  def change
    add_column :crops, :plantings_count, :integer
  end
end
