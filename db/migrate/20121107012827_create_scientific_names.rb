class CreateScientificNames < ActiveRecord::Migration
  def change
    create_table :scientific_names do |t|
      t.string :scientific_name, null: false
      t.integer :crop_id, null: false

      t.timestamps null: true
    end
  end
end
