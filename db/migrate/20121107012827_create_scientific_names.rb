# frozen_string_literal: true

class CreateScientificNames < ActiveRecord::Migration[4.2]
  def change
    create_table :scientific_names do |t|
      t.string :scientific_name, null: false
      t.integer :crop_id, null: false

      t.timestamps null: true
    end
  end
end
