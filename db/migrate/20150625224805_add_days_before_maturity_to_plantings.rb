# frozen_string_literal: true

class AddDaysBeforeMaturityToPlantings < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :days_before_maturity, :integer
  end
end
