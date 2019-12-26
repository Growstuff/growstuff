# frozen_string_literal: true

class AddSiWeightToHarvest < ActiveRecord::Migration[4.2]
  def change
    add_column :harvests, :si_weight, :float
  end
end
