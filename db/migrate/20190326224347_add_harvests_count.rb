# frozen_string_literal: true

class AddHarvestsCount < ActiveRecord::Migration[5.2]
  def change
    add_column :plantings, :harvests_count, :integer, default: 0
    Planting.reset_column_information
    Planting.unscoped.pluck(:id).each do |planting_id|
      Planting.reset_counters(planting_id, :harvests)
    end
  end
end
