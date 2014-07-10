class RemoveTradableFromSeeds < ActiveRecord::Migration
  def up
    remove_column :seeds, :tradable
  end

  def down
    add_column :seeds, :tradable, :boolean
  end
end
