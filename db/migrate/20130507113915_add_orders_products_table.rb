# frozen_string_literal: true

class AddOrdersProductsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :orders_products, id: false do |t|
      t.integer :order_id
      t.integer :product_id
    end
  end
end
