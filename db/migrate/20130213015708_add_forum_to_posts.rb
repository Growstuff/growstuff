class AddForumToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :forum_id, :integer
  end
end
