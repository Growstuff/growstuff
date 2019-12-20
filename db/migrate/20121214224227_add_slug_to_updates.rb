# frozen_string_literal: true

class AddSlugToUpdates < ActiveRecord::Migration[4.2]
  def change
    add_column :updates, :slug, :string
    add_index :updates, :slug, unique: true
  end
end
