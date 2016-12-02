class CreateSeeds < ActiveRecord::Migration
  def change
    create_table :seeds do |t|
      t.integer :owner_id, null: false
      t.integer :crop_id, null: false
      t.text :description
      t.integer :quantity
      t.date :use_by

      t.timestamps null: true
    end
  end
end
