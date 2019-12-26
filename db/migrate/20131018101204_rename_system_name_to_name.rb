# frozen_string_literal: true

class RenameSystemNameToName < ActiveRecord::Migration[4.2]
  def up
    # Rails is smart enough to alter the column being indexed, but not the name
    # of the index, and there's no rename_index command.
    remove_index :crops, :system_name
    rename_column :crops, :system_name, :name
    add_index :crops, :name
  end

  def down
    remove_index :crops, :name
    rename_column :crops, :name, :system_name
    add_index :crops, :system_name
  end
end
