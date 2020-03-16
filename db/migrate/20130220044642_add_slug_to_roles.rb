# frozen_string_literal: true

class AddSlugToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :slug, :string
    add_index :roles, :slug, unique: true
  end
end
