class AddHarvestCountToCrop < ActiveRecord::Migration[5.2]
  def change
    change_table :crops do |t|
      t.integer :harvests_count, default: 0
      t.integer :photo_associations_count, default: 0
    end
    change_table :plant_parts do |t|
      t.integer :harvests_count, default: 0
    end
    change_table :posts do |t|
      t.integer :comments_count, default: 0
    end
    reversible do |dir|
      dir.up { data }
    end
  end

  def data
    execute <<-SQL.squish
        UPDATE crops
           SET harvests_count = (
             SELECT count(1)
               FROM harvests
              WHERE harvests.crop_id = crops.id
              )
    SQL
    execute <<-SQL.squish
        UPDATE crops
           SET photo_associations_count = (
             SELECT count(1)
               FROM photo_associations
              WHERE photo_associations.crop_id = crops.id
              )
    SQL
    execute <<-SQL.squish
        UPDATE plant_parts
           SET harvests_count = (
             SELECT count(1)
               FROM harvests
              WHERE harvests.plant_part_id = plant_parts.id
              )
    SQL

    execute <<-SQL.squish
        UPDATE posts
           SET comments_count = (
             SELECT count(1)
               FROM comments
              WHERE comments.post_id = posts.id
              )
    SQL
  end
end
