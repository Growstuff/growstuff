# frozen_string_literal: true

class CreateStalls < ActiveRecord::Migration[8.1]
  def change
    create_table :stalls do |t|
      t.references :member, null: false, foreign_key: true, index: { unique: true }
      t.datetime :opened_at
      t.timestamps
    end
  end
end
