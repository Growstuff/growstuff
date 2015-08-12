class AddDeletedToMembers < ActiveRecord::Migration
  def change
    add_column :members, :deleted?, :boolean, :default => false
  end
end