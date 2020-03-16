# frozen_string_literal: true

class RenameUsersToMembers < ActiveRecord::Migration[4.2]
  def change
    rename_table :users, :members
    rename_column :members, :username, :login_name
    rename_column :gardens, :user_id, :member_id
    rename_column :posts, :user_id, :member_id
  end
end
