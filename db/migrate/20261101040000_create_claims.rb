# frozen_string_literal: true

class CreateClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :claims do |t|
      t.references :stall_seed, null: false, foreign_key: true, index: { unique: true }
      t.references :member, null: false, foreign_key: true
      t.text :note
      t.timestamps
    end
  end
end
