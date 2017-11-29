class CreatePhotographings < ActiveRecord::Migration
  def change
    create_table :photographings do |t|
      t.integer :photo_id
      t.integer :photographable_id
      t.string :photographable_type
      t.timestamps null: false
    end
    add_index :photographings, %i(photographable_id photographable_type photo_id),
      name: 'polymorphic_many_to_many_idx'
    add_index :photographings, %i(photographable_id photographable_type),
      name: 'polymorphic_photographable_idx'
  end
end
