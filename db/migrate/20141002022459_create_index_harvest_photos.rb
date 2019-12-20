# frozen_string_literal: true

class CreateIndexHarvestPhotos < ActiveRecord::Migration[4.2]
  def change
    add_index(:harvests_photos, %i(harvest_id photo_id))
  end
end
