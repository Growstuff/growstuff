# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[4.2]
  def change
    create_table :orders do |t|
      t.string :member_id, null: false

      t.timestamps null: true
    end
  end
end
