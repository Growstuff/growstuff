class ChangeOrderMemberIdToInteger < ActiveRecord::Migration
  def change
    change_column :orders, :member_id, :integer
  end
end
