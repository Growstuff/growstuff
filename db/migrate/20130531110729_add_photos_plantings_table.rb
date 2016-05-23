class AddPhotosPlantingsTable < ActiveRecord::Migration
  def change
    create_table :photos_plantings, id: false do |t|
      t.integer :photo_id
      t.integer :planting_id
    end
  end
end
