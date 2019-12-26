# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.integer :post_id
      t.integer :author_id
      t.text :body

      t.timestamps null: true
    end
  end
end
