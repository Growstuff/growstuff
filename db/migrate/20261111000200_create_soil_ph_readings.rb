# frozen_string_literal: true

class CreateSoilPhReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :soil_ph_readings do |t|
      t.references :garden, null: false, foreign_key: true
      t.date :measured_on, null: false
      t.decimal :ph, precision: 4, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :soil_ph_readings, 'ph >= 0 AND ph <= 14', name: 'soil_ph_readings_ph_range'
  end
end
