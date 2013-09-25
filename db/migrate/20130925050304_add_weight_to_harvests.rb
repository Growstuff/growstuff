class AddWeightToHarvests < ActiveRecord::Migration
  def change
    add_column :harvests, :weight_quantity, :decimal
    add_column :harvests, :weight_unit, :string
  end
end
