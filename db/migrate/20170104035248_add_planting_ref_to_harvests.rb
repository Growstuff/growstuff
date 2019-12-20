# frozen_string_literal: true

class AddPlantingRefToHarvests < ActiveRecord::Migration[4.2]
  def change
    add_reference :harvests, :planting, index: true, foreign_key: true
  end
end
