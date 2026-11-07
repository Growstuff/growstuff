# frozen_string_literal: true

# Frost dates for a cell of the weather grid, worked out once from its history by FrostCalculator,
# so a page reads one row and nothing is calculated as it loads. Keyed by the cell, as WeatherReading is.
# Approximate, regional and for entertainment only.
class CreateFrostYearsAndFrostStats < ActiveRecord::Migration[8.1]
  def change
    create_table :frost_years do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.integer :year, null: false, comment: 'The frost year, named for the calendar year it ends in.'
      t.float :threshold_c, null: false, comment: 'A day at or below this counts as frost.'
      t.date :first_frost, comment: 'Null when the year had no frost.'
      t.date :last_frost, comment: 'Null when the year had no frost.'
      t.float :lowest_c, comment: 'The lowest minimum temperature of the year.'
      t.timestamps

      t.index %i(latitude longitude threshold_c year), unique: true, name: 'index_frost_years_on_cell_threshold_and_year'
    end

    create_table :frost_stats do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :threshold_c, null: false, comment: 'A day at or below this counts as frost.'
      t.string :status, null: false, comment: 'frost, possible, rare or unknown: how often the cell has any frost.'
      t.integer :years_used, null: false, default: 0, comment: 'Complete frost years in the history.'
      t.integer :frost_years, null: false, default: 0, comment: 'How many of those years had any frost.'
      t.float :first_frost_median, comment: 'Days into the frost year. Null when the status is rare or unknown.'
      t.float :first_frost_p10, comment: 'Days into the frost year: an early warning, 1 year in 10 is earlier.'
      t.float :last_frost_median, comment: 'Days into the frost year.'
      t.float :last_frost_p90, comment: 'Days into the frost year: a safe-to-plant date, 1 year in 10 is later.'
      t.float :frost_free_days_median, comment: 'Only for the frost status.'
      t.datetime :computed_at, null: false
      t.timestamps

      t.index %i(latitude longitude threshold_c), unique: true, name: 'index_frost_stats_on_cell_and_threshold'
    end
  end
end
