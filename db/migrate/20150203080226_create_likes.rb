class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.references :member, index: true
      t.references :likeable, polymorphic: true, index: true
      t.string :categories, array: true

      t.timestamps
    end

    add_index :likes, :likeable_id
  end
end
