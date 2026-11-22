# frozen_string_literal: true

class AddSourcePlantingToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_reference :plantings, :source_planting, foreign_key: { to_table: :plantings }
  end
end
