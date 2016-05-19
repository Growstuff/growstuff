class AddHarvestsPhotosTable < ActiveRecord::Migration
  def change
    create_table :harvests_photos, id: false do |t|
      t.integer :photo_id
      t.integer :harvest_id
    end
  end
end
