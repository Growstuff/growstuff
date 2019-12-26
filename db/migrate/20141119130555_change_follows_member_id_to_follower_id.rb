# frozen_string_literal: true

class ChangeFollowsMemberIdToFollowerId < ActiveRecord::Migration[4.2]
  def change
    rename_column :follows, :member_id, :follower_id
  end
end
