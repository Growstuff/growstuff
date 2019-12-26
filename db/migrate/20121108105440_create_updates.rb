# frozen_string_literal: true

class CreateUpdates < ActiveRecord::Migration[4.2]
  def change
    create_table :updates do |t|
      t.integer :user_id, null: false
      t.string :subject, null: false
      t.text :body, null: false

      t.timestamps null: true
    end
  end
end
