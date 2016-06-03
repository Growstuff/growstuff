class CreateOrderItems < ActiveRecord::Migration
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
