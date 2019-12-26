# frozen_string_literal: true

class PostCommentCounterCache < ActiveRecord::Migration[5.2]
  def change
    change_table :posts do |t|
      t.integer :comments_count, default: 0
    end
    reversible do |dir|
      dir.up { set_counter_value }
    end
  end

  def set_counter_value
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
