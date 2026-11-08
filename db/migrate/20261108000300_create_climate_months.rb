# frozen_string_literal: true

# One month of weather for a cell of the weather grid, summarised from its daily figures by ClimateSummary, so a page can
# show what is usual for a place and how this year compares without reading thousands of days. Keyed by the cell, as
# WeatherReading is. Approximate and regional: the figures come from a model of about 25 km.
class CreateClimateMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :climate_months do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.integer :year, null: false
      t.integer :month, null: false, comment: '1 for January to 12 for December.'
      t.integer :days, null: false, comment: 'How many days of the month the figures are from.'
      t.float :rain_mm, comment: 'Rain over those days.'
      t.float :temp_mean_c, comment: 'The average of the days\' mean air temperature.'
      t.float :temp_max_c, comment: 'The hottest day\'s highest air temperature.'
      t.date :temp_max_on
      t.float :temp_min_c, comment: 'The coldest night\'s lowest air temperature.'
      t.date :temp_min_on
      t.float :soil_temp_c, comment: 'The average of the days\' mean temperature of the top 7 cm of soil.'
      t.float :soil_temp_max_c
      t.date :soil_temp_max_on
      t.float :soil_temp_min_c
      t.date :soil_temp_min_on
      t.timestamps

      t.index %i(latitude longitude year month), unique: true, name: 'index_climate_months_on_cell_year_and_month'
    end
  end
end
