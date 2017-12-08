class AddPhotosSeedsTable < ActiveRecord::Migration
  def change
    create_table :photos_seeds, id: false do |t|
      t.integer :photo_id
      t.integer :seed_id
    end
    add_index(:photos_seeds, %i(seed_id photo_id))
  end
end
