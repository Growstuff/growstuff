class AddExpressTokenToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :paypal_express_token, :string
    add_column :orders, :paypal_express_payer_id, :string
  end
end
