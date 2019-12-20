# frozen_string_literal: true

class AddSlugToSeed < ActiveRecord::Migration[4.2]
  def change
    add_column :seeds, :slug, :string
    add_index :seeds, :slug, unique: true
  end
end
