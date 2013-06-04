class ChangeOrderMemberIdToInteger < ActiveRecord::Migration
  def up
    remove_column :orders, :member_id
    add_column :orders, :member_id, :integer
  end

  def down
    remove_column :orders, :member_id
    add_column :orders, :member_id, :string
  end
end
