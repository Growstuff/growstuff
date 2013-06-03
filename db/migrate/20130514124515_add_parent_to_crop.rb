class AddParentToCrop < ActiveRecord::Migration
  def change
    add_column :crops, :parent_id, :integer
  end
end
