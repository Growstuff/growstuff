# frozen_string_literal: true

class CreateOrderItems < ActiveRecord::Migration[4.2]
  def change
    create_table :order_items do |t|
      t.integer :order_id
      t.integer :product_id
      t.decimal :price
      t.integer :quantity

      t.timestamps null: true
    end
  end
end
