# frozen_string_literal: true

class CreateAuthentications < ActiveRecord::Migration[4.2]
  def change
    create_table :authentications do |t|
      t.integer :member_id, null: false
      t.string :provider, null: false
      t.string :uid
      t.string :token
      t.string :secret
      t.timestamps null: true
    end
    add_index :authentications, :member_id
  end
end
