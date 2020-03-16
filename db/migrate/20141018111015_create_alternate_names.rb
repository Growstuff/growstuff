# frozen_string_literal: true

class CreateAlternateNames < ActiveRecord::Migration[4.2]
  def change
    create_table :alternate_names do |t|
      t.string :name, null: false
      t.integer :crop_id, null: false
      t.integer :creator_id, null: false

      t.timestamps null: true
    end
  end
end
