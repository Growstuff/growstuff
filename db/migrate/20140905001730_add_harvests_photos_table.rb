# frozen_string_literal: true

class AddHarvestsPhotosTable < ActiveRecord::Migration[4.2]
  def change
    create_table :harvests_photos, id: false do |t|
      t.integer :photo_id
      t.integer :harvest_id
    end
  end
end
