class AddColumnsToProduct < ActiveRecord::Migration
  def change
    add_column :products, :account_type_id, :integer
    add_column :products, :paid_months, :integer
  end
end
