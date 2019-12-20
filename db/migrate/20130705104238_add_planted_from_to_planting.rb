# frozen_string_literal: true

class AddPlantedFromToPlanting < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :planted_from, :string
  end
end
