# frozen_string_literal: true

class CropHarvestCounterCache < ActiveRecord::Migration[5.2]
  def change
    change_table :crops do |t|
      t.integer :harvests_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
    execute <<-SQL.squish
        UPDATE crops
           SET harvests_count = (
             SELECT count(1)
               FROM harvests
              WHERE harvests.crop_id = crops.id
              )
    SQL
  end
end
