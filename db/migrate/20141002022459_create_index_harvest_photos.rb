class CreateIndexHarvestPhotos < ActiveRecord::Migration
  def change
	add_index(:harvests_photos, [:harvest_id, :photo_id])
  end
end
