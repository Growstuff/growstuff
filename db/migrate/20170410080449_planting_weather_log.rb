class PlantingWeatherLog < ActiveRecord::Migration
  def change
    create_table :planting_weather_logs do |t|
      t.integer :planting_id
      t.timestamps
      t.json 'weather_data'
    end

    add_index :planting_weather_logs, :planting_id
  end
end
