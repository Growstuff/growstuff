# frozen_string_literal: true

class CreateObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :observations do |t|
      t.references :planting, null: false, foreign_key: true, index: false
      t.references :author, null: false, foreign_key: { to_table: :members }
      t.string :kind # nil is "other"
      t.datetime :observed_at, null: false
      t.text :description

      t.timestamps
    end
    add_index :observations, %i(planting_id observed_at)
  end
end
