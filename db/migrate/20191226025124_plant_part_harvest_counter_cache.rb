# frozen_string_literal: true

class PlantPartHarvestCounterCache < ActiveRecord::Migration[5.2]
  def change
    change_table :plant_parts do |t|
      t.integer :harvests_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
    execute <<-SQL.squish
        UPDATE plant_parts
           SET harvests_count = (
             SELECT count(1)
               FROM harvests
              WHERE harvests.plant_part_id = plant_parts.id
              )
    SQL
  end
end
