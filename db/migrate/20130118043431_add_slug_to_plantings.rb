# frozen_string_literal: true

class AddSlugToPlantings < ActiveRecord::Migration[4.2]
  def change
    add_column :plantings, :slug, :string
    add_index :plantings, :slug, unique: true
  end
end
