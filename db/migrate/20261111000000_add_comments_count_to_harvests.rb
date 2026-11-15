# frozen_string_literal: true

class AddCommentsCountToHarvests < ActiveRecord::Migration[8.1]
  def change
    change_table :harvests do |t|
      t.integer :comments_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
    execute <<~SQL.squish
      UPDATE harvests
         SET comments_count = (
           SELECT count(1)
             FROM comments
            WHERE comments.commentable_id = harvests.id
            AND comments.commentable_type = 'Harvest'
          )
    SQL
  end
end
