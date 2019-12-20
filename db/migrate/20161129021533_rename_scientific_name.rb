# frozen_string_literal: true

class RenameScientificName < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :scientific_names, :scientific_name, :name
  end

  def self.down
    rename_column :scientific_names, :name, :scientific_name
  end
end
