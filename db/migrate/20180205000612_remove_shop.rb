class RemoveShop < ActiveRecord::Migration
  def up
    drop_table :order_items
    drop_table :orders
    drop_table :products
    drop_table :account_types
    drop_table :accounts
  end
end
