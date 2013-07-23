class SetDefaultTradableToOnSeed < ActiveRecord::Migration
  def up
    change_column_default(:seeds, :tradable_to, 'nowhere')
  end

  def down
    change_column_default(:seeds, :tradable_to, nil)
  end
end
