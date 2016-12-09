class AddCreationIndexToUpdates < ActiveRecord::Migration
  def change
    add_index :updates, [:created_at, :user_id]
  end
end
