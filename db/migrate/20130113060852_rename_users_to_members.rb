class RenameUsersToMembers < ActiveRecord::Migration
  def change
    rename_table :users, :members
    rename_column :gardens, :user_id, :member_id
    rename_column :posts, :user_id, :member_id
  end
end
