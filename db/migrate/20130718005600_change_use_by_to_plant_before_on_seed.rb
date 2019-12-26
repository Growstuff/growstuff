# frozen_string_literal: true

class ChangeUseByToPlantBeforeOnSeed < ActiveRecord::Migration[4.2]
  def change
    rename_column :seeds, :use_by, :plant_before
  end
end
