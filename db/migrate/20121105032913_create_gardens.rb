# frozen_string_literal: true

class CreateGardens < ActiveRecord::Migration[4.2]
  def change
    create_table :gardens do |t|
      t.string  :name, null: false
      t.integer :user_id
      t.string  :slug, null: false

      t.timestamps null: true
    end

    add_index :gardens, :user_id
    add_index :gardens, :slug, unique: true
  end
end
