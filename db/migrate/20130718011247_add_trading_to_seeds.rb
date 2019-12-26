# frozen_string_literal: true

class AddTradingToSeeds < ActiveRecord::Migration[4.2]
  def change
    add_column :seeds, :tradable, :boolean
    add_column :seeds, :tradable_to, :string
  end
end
