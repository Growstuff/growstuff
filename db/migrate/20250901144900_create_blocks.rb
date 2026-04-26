# frozen_string_literal: true

class CreateBlocks < ActiveRecord::Migration[6.1]
  def change
    create_table :blocks do |t|
      t.references :blocker, foreign_key: { to_table: :members }
      t.references :blocked, foreign_key: { to_table: :members }

      t.timestamps
    end
    add_index :blocks, [:blocker_id, :blocked_id], unique: true
  end
end
