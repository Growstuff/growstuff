# frozen_string_literal: true

class AddShortCodeToPlantings < ActiveRecord::Migration[8.1]
  def change
    add_column :plantings, :short_code, :string, limit: 10
    add_index :plantings, %i[owner_id short_code]
  end
end
