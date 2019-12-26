# frozen_string_literal: true

class AddSlugToPlantPart < ActiveRecord::Migration[4.2]
  def change
    add_column :plant_parts, :slug, :string
  end
end
