class AddTradingToSeeds < ActiveRecord::Migration
  def change
    add_column :seeds, :tradable, :boolean
    add_column :seeds, :tradable_to, :string
  end
end
