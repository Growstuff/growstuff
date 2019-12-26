# frozen_string_literal: true

class CreatePlantParts < ActiveRecord::Migration[4.2]
  def change
    create_table :plant_parts do |t|
      t.string :name

      t.timestamps null: true
    end
  end
end
