# frozen_string_literal: true

# One day's weather for a cell of a weather grid. Keyed by place, not by planting, so every
# garden in the same cell shares the one series. A value is null when the source had no figure.
class CreateWeatherReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :weather_readings do |t|
      t.float :latitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.float :longitude, null: false, comment: 'Centre of the grid cell, in degrees.'
      t.date :date, null: false
      t.string :source, null: false, comment: 'Where the reading came from, e.g. open-meteo.'
      t.float :rainfall_mm
      t.float :temp_max_c
      t.float :temp_min_c
      t.float :evapotranspiration_mm, comment: 'Reference evapotranspiration: how much water a lawn would lose.'
      t.float :wind_max_kmh
      t.float :radiation_mj_m2, comment: 'Sunlight energy reaching the ground.'
      t.float :temp_mean_c
      t.float :feels_like_max_c, comment: 'What the day felt like, with wind and humidity.'
      t.float :feels_like_min_c
      t.float :feels_like_mean_c
      t.float :soil_temp_c, comment: 'Mean temperature of the top 7cm of soil.'
      t.float :soil_moisture_m3_m3, comment: 'Water in the top 7cm of soil, as a fraction of its volume.'
      t.float :sunshine_seconds
      t.float :daylight_seconds
      t.float :cloud_cover_percent
      t.float :humidity_percent
      t.float :dew_point_c
      t.float :vapour_pressure_deficit_kpa, comment: 'How thirsty the air is; high values stress plants.'
      t.float :snowfall_cm
      t.float :precipitation_hours
      t.float :wind_gust_max_kmh
      t.float :wind_direction_degrees, comment: 'Where the wind blew from, 0 to 360.'
      t.float :pressure_hpa
      t.integer :weather_code, comment: 'WMO code for the day, e.g. 2 is partly cloudy.'
      t.timestamps
    end
    add_index :weather_readings, %i(latitude longitude date), unique: true
  end
end
