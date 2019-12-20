# frozen_string_literal: true

class DefaultPlantingsCountToZero < ActiveRecord::Migration[4.2]
  def up
    change_column :crops, :plantings_count, :integer, default: 0
  end

  def down
    change_column :crops, :plantings_count, :integer, default: nil
  end
end
