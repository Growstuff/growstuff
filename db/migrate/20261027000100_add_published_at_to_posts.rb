# frozen_string_literal: true

# When a post was published. A post with none is a draft, which only its author can see.
class AddPublishedAtToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :published_at, :datetime
    execute 'UPDATE posts SET published_at = COALESCE(created_at, NOW())'
    add_index :posts, :published_at
  end

  def down
    remove_column :posts, :published_at
  end
end
