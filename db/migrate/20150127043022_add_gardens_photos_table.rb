# frozen_string_literal: true

class AddGardensPhotosTable < ActiveRecord::Migration[4.2]
  def change
    create_table :gardens_photos, id: false do |t|
      t.integer :photo_id
      t.integer :garden_id
    end
    add_index(:gardens_photos, %i(garden_id photo_id))
  end
end
