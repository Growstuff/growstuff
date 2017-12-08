class AddCropsPostsTable < ActiveRecord::Migration
  def change
    create_table :crops_posts, id: false do |t|
      t.integer :crop_id
      t.integer :post_id
    end
    add_index :crops_posts, %i(crop_id post_id)
    add_index :crops_posts, :crop_id
  end
end
