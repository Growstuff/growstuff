# frozen_string_literal: true

class ChangeOrderMemberIdToInteger < ActiveRecord::Migration[4.2]
  def up
    remove_column :orders, :member_id
    add_column :orders, :member_id, :integer
  end

  def down
    remove_column :orders, :member_id
    add_column :orders, :member_id, :string
  end
end
