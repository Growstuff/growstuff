# frozen_string_literal: true

class CreateStallSeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :stall_seeds do |t|
      t.references :stall, null: false, foreign_key: true
      t.references :seed, null: false, foreign_key: true, index: false
      t.timestamps
    end
    add_index :stall_seeds, %i(seed_id stall_id), unique: true
  end
end
