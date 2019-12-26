# frozen_string_literal: true

class AddFieldsToGardens < ActiveRecord::Migration[4.2]
  def change
    add_column :gardens, :active, :boolean, default: true
    add_column :gardens, :location, :string
    add_column :gardens, :latitude, :float
    add_column :gardens, :longitude, :float
    add_column :gardens, :area, :decimal
    add_column :gardens, :area_unit, :string
  end
end
