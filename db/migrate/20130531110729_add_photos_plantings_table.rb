# frozen_string_literal: true

class AddPhotosPlantingsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :photos_plantings, id: false do |t|
      t.integer :photo_id
      t.integer :planting_id
    end
  end
end
