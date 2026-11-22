# frozen_string_literal: true

# What the weather did in a cell of the weather grid, kept once for the place instead of once for every planting in it.
# A planting's own days (colder or hotter than its crop takes) stay in planting_conditions.
class CreatePlaceConditions < ActiveRecord::Migration[8.1]
  MOVED_KINDS = %w(frost damaging_wind heavy_rain extreme_heat first_snow).freeze

  def up
    create_table :place_conditions do |t|
      t.float :latitude, null: false, comment: "Centre of the weather grid cell, in degrees."
      t.float :longitude, null: false, comment: "Centre of the weather grid cell, in degrees."
      t.string :kind, null: false, comment: "What the weather did: frost, damaging_wind, heavy_rain, extreme_heat or first_snow."
      t.date :occurred_on, null: false
      t.float :value, comment: "The day's figure for the kind: lowest temperature for frost, gust, rain, highest temperature, or snow."
      t.float :threshold, comment: "The limit the day crossed, as it was when the day was recorded."
      t.float :direction_degrees, comment: "Damaging wind: where it blew from, 0 to 360."
      t.float :temp_min_c, comment: "Damaging wind: the day's lowest air temperature in degrees Celsius."
      t.float :temp_max_c, comment: "Damaging wind: the day's highest air temperature in degrees Celsius."

      t.timestamps
    end
    add_index :place_conditions, %i(latitude longitude kind occurred_on), unique: true, name: 'index_place_conditions_on_cell_kind_and_day'

    execute("DELETE FROM planting_conditions WHERE kind IN (#{MOVED_KINDS.map { |kind| connection.quote(kind) }.join(', ')})")
    remove_columns :planting_conditions, :direction_degrees, :temp_min_c, :temp_max_c
  end

  def down
    change_table :planting_conditions, bulk: true do |t|
      t.float :direction_degrees, comment: "Damaging wind: where it blew from, 0 to 360."
      t.float :temp_min_c, comment: "Damaging wind: the day's lowest air temperature in degrees Celsius."
      t.float :temp_max_c, comment: "Damaging wind: the day's highest air temperature in degrees Celsius."
    end
    drop_table :place_conditions
  end
end
