# frozen_string_literal: true

class AddForumToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :forum_id, :integer
  end
end
