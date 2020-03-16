# frozen_string_literal: true

class AddSlugToCrops < ActiveRecord::Migration[4.2]
  def change
    add_column :crops, :slug, :string
    add_index :crops, :slug, unique: true
  end
end
