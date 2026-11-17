# frozen_string_literal: true

class CreatePlantingConditions < ActiveRecord::Migration[8.1]
  def change
    create_table :planting_conditions do |t|
      t.references :planting, null: false, foreign_key: true, index: false
      t.string :kind, null: false, comment: "What the planting went through: frost, killing_cold or killing_heat."
      t.date :occurred_on, null: false
      t.float :value, comment: "The day's lowest air temperature for frost and killing cold, highest for killing heat, in degrees Celsius."
      t.float :threshold, comment: "The limit the day crossed, in degrees Celsius, as it was when the day was recorded."

      t.timestamps
    end
    add_index :planting_conditions, %i(planting_id kind occurred_on), unique: true,
                                                                      name:   'index_planting_conditions_on_planting_kind_and_day'
  end
end
