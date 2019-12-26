# frozen_string_literal: true

class RequireSystemNameForCrops < ActiveRecord::Migration[4.2]
  def up
    change_table :crops do |t|
      t.index :system_name
      t.change :system_name, :string, null: false
    end
  end

  def down
    change_table :crops do |t|
      t.change :system_name, :string, null: true
      t.remove_index :system_name
    end
  end
end
