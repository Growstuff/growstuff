# frozen_string_literal: true

class AddSlugToForums < ActiveRecord::Migration[4.2]
  def change
    add_column :forums, :slug, :string
    add_index :forums, :slug, unique: true
  end
end
