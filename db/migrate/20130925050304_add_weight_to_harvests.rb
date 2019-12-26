# frozen_string_literal: true

class AddWeightToHarvests < ActiveRecord::Migration[4.2]
  def change
    add_column :harvests, :weight_quantity, :decimal
    add_column :harvests, :weight_unit, :string
  end
end
