# frozen_string_literal: true

class AddFieldsToCrops < ActiveRecord::Migration[5.2]
  def change
    add_column :crops, :row_spacing, :integer
    add_column :crops, :spread, :integer
    add_column :crops, :height, :integer
    add_column :crops, :sowing_method, :string
    add_column :crops, :sun_requirements, :string
    add_column :crops, :growing_degree_days, :integer
  end
end
