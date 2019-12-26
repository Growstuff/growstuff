# frozen_string_literal: true

class AddExpressTokenToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :paypal_express_token, :string
    add_column :orders, :paypal_express_payer_id, :string
  end
end
