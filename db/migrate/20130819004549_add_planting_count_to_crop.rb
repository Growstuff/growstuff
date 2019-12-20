# frozen_string_literal: true

class AddPlantingCountToCrop < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :plantings_count, :integer
  end
end
