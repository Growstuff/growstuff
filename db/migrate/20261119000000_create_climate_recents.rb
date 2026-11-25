# frozen_string_literal: true

# The average air temperature of the latest 30 days, for a cell of the weather grid, so a place's page can say how the
# last month has been without reading daily weather. ClimateMonth keeps whole months, which can't answer that. One row for
# each cell, replaced each time its latest months are fetched. Approximate and regional: the figures come from a model of about 25 km.
class CreateClimateRecents < ActiveRecord::Migration[8.1]
  def change
    create_table :climate_recents do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.date :starts_on, null: false, comment: 'The first day of the 30.'
      t.date :ends_on, null: false, comment: 'The last day we had weather for.'
      t.integer :days, null: false, comment: 'How many of the days had an air temperature.'
      t.float :temp_mean_c, comment: 'The average of those days\' mean air temperature.'
      t.timestamps

      t.index %i(latitude longitude), unique: true, name: 'index_climate_recents_on_cell'
    end
  end
end
