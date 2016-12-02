class AddDaysBeforeMaturityToPlantings < ActiveRecord::Migration
  def change
    add_column :plantings, :days_before_maturity, :integer
  end
end
