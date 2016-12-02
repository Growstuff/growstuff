class CreateForums < ActiveRecord::Migration
  def change
    create_table :forums do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.integer :owner_id, null: false

      t.timestamps null: true
    end
  end
end
