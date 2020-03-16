# frozen_string_literal: true

class CreateAccountDetails < ActiveRecord::Migration[4.2]
  def change
    create_table :account_details do |t|
      t.integer :member_id, null: false
      t.integer :account_type_id
      t.datetime :paid_until

      t.timestamps null: true
    end
  end
end
