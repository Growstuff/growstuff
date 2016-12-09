class ChangePlantedAtToDate < ActiveRecord::Migration
  def change
    change_column :plantings, :planted_at, :date
  end
end
