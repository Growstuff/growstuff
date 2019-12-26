# frozen_string_literal: true

class CropPhotoCounterCache < ActiveRecord::Migration[5.2]
  def change
    change_table :crops do |t|
      t.integer :photo_associations_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
    execute <<-SQL.squish
        UPDATE crops
           SET photo_associations_count = (
             SELECT count(1)
               FROM photo_associations
              WHERE photo_associations.crop_id = crops.id
              )
    SQL
  end
end
