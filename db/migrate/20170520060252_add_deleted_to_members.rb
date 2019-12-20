# frozen_string_literal: true

class AddDeletedToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :deleted_at, :datetime
    add_index :members, :deleted_at
  end
end
