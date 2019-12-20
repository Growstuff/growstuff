# frozen_string_literal: true

class CreatePlantings < ActiveRecord::Migration[4.2]
  def change
    create_table :plantings do |t|
      t.integer :garden_id, null: false
      t.integer :crop_id, null: false
      t.datetime :planted_at
      t.integer :quantity
      t.text :description

      t.timestamps null: true
    end
  end
end
