class AddFinishedToPlanting < ActiveRecord::Migration
  def change
    add_column :plantings, :finished, :boolean, default: false
    add_column :plantings, :finished_at, :date
  end
end
