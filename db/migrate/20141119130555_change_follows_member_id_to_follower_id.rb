class ChangeFollowsMemberIdToFollowerId < ActiveRecord::Migration
  def change
  	rename_column :follows, :member_id, :follower_id
  end
end
