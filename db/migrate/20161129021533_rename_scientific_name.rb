class RenameScientificName < ActiveRecord::Migration
  def self.up
    rename_column :scientific_names, :scientific_name, :name
  end

  def self.down
    rename_column :scientific_names, :name, :scientific_name
  end
end
