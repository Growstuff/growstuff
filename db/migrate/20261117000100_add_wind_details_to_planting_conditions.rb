# frozen_string_literal: true

class AddWindDetailsToPlantingConditions < ActiveRecord::Migration[8.1]
  def change
    change_table :planting_conditions, bulk: true do |t|
      t.float :direction_degrees, comment: "Damaging wind: where it blew from, 0 to 360."
      t.float :temp_min_c, comment: "Damaging wind: the day's lowest air temperature in degrees Celsius."
      t.float :temp_max_c, comment: "Damaging wind: the day's highest air temperature in degrees Celsius."
    end
  end
end
