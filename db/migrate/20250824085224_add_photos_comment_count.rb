# frozen_string_literal: true

class AddPhotosCommentCount < ActiveRecord::Migration[7.2]
  def change
    change_table :photos do |t|
      t.integer :comments_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
    execute <<~SQL.squish
      UPDATE photos
         SET comments_count = (
           SELECT count(1)
             FROM comments
            WHERE comments.commentable_id = comments.id
            AND comments.commentable_type = 'Photo'
          )
    SQL
  end
end
