# frozen_string_literal: true

class AddWeatherObservations < ActiveRecord::Migration[7.0]
  def change
    # See https://github.com/schemaorg/schemaorg/issues/362
    create_table :weather_observations do |t|
      t.string :source
      t.datetime :observation_at
      t.integer :solar_uv_index
      t.decimal :wind_speed_kmh
      t.decimal :wind_gust_speed_kmh
      t.string :wind_direction
      t.decimal :air_temperature_centigrade
      t.decimal :relative_humidity
      t.decimal :precipitation_probability
      t.decimal :dew_point_temperature_centigrade
      t.decimal :pressure
      t.string :visibility
      t.string :weather_type
      t.references :garden_id
      t.timestamps
    end
  end
end
