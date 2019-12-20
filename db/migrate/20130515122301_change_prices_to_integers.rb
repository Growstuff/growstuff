# frozen_string_literal: true

class ChangePricesToIntegers < ActiveRecord::Migration[4.2]
  def up
    change_column :order_items, :price, :integer
    change_column :products, :min_price, :integer
  end

  def down
    change_column :order_items, :price, :decimal
    change_column :products, :min_price, :decimal
  end
end
