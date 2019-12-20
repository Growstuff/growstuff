# frozen_string_literal: true

class AddLikeCounterCaches < ActiveRecord::Migration[5.2]
  def change
    change_table :photos do |t|
      t.integer :likes_count, default: 0
    end
    change_table :posts do |t|
      t.integer :likes_count, default: 0
    end
    reversible do |dir|
      dir.up { data }
    end
  end

  def data
    execute <<-SQL.squish
        UPDATE photos
           SET likes_count = (
             SELECT count(1)
               FROM likes
              WHERE likes.likeable_id = photos.id
              AND likeable_type = 'Photo'
              )
    SQL
    execute <<-SQL.squish
        UPDATE posts
           SET likes_count = (
             SELECT count(1)
               FROM likes
              WHERE likes.likeable_id = posts.id
              AND likeable_type = 'Post'
              )
    SQL
  end
end
