# frozen_string_literal: true

class CreateFollows < ActiveRecord::Migration[4.2]
  def change
    create_table :follows do |t|
      t.integer :member_id
      t.integer :followed_id

      t.timestamps null: true
    end
  end
end
