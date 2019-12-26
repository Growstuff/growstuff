# frozen_string_literal: true

class AddColumnsToProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :account_type_id, :integer
    add_column :products, :paid_months, :integer
  end
end
