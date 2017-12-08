class AddCreationIndexToUpdates < ActiveRecord::Migration
  def change
    add_index :updates, %i(created_at user_id)
  end
end
