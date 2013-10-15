class ChangeHarvestNotesToDescription < ActiveRecord::Migration
  def change
    rename_column :harvests, :notes, :description
  end
end
