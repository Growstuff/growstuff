# frozen_string_literal: true

class AddSlugToHarvests < ActiveRecord::Migration[4.2]
  def change
    add_column :harvests, :slug, :string
  end
end
