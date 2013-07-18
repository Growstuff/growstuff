class ChangeUseByToPlantBeforeOnSeed < ActiveRecord::Migration
  def change
    rename_column :seeds, :use_by, :plant_before
  end
end
