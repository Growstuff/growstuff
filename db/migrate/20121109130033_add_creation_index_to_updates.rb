# frozen_string_literal: true

class AddCreationIndexToUpdates < ActiveRecord::Migration[4.2]
  def change
    add_index :updates, %i(created_at user_id)
  end
end
