# frozen_string_literal: true

class ChangeHarvestUnitsToUnit < ActiveRecord::Migration[4.2]
  def change
    rename_column :harvests, :units, :unit
  end
end
