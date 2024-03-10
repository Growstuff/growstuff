# frozen_string_literal: true
class AddSlugToActivity < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :slug, :string
    add_index :activities, :slug, unique: true
  end
end
