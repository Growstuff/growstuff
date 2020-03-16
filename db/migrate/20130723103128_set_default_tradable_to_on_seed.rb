# frozen_string_literal: true

class SetDefaultTradableToOnSeed < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:seeds, :tradable_to, 'nowhere')
  end

  def down
    change_column_default(:seeds, :tradable_to, nil)
  end
end
