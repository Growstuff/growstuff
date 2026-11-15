# frozen_string_literal: true

# A cell of the weather grid someone asked to see the climate of, by setting their location there or by looking at a place
# we hold none for. ClimateUpdater fetches these cells before any others, and removes the request once it has.
class CreateClimateRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :climate_requests do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.datetime :requested_at, null: false, comment: 'When the cell was first asked for, so the longest waiting is fetched first.'
      t.timestamps

      t.index %i(latitude longitude), unique: true, name: 'index_climate_requests_on_cell'
    end
  end
end
