class AddMemberCountCaches < ActiveRecord::Migration
  def change
    add_column :members, :photos_count, :integer
    add_column :members, :forums_count, :integer
  end
end
