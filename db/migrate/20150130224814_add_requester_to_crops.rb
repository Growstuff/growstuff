class AddRequesterToCrops < ActiveRecord::Migration
  def change
    add_column :crops, :requester_id, :integer
    add_index :crops, :requester_id
  end
end
