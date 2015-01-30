class AddRequesterAndApprovedToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :requester_id, :integer
    add_column :crops, :approved, :boolean, default: true
    add_index :crops, :requester_id
  end
end
