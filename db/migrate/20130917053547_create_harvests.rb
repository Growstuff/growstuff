# frozen_string_literal: true

class CreateHarvests < ActiveRecord::Migration[4.2]
  def change
    create_table :harvests do |t|
      t.integer :crop_id, null: false
      t.integer :owner_id, null: false
      t.date :harvested_at
      t.decimal :quantity
      t.string :units
      t.text :notes

      t.timestamps null: true
    end
  end
end
