class AddPhotosSeedsTable < ActiveRecord::Migration
  def change
    create_table :photos_seeds, id: false do |t|
      t.integer :photo_id
      t.integer :seed_id
    end
  end
end
