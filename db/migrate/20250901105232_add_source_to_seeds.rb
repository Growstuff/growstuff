# frozen_string_literal: true

class AddSourceToSeeds < ActiveRecord::Migration[7.2]
  def change
    add_column :seeds, :source, :string
    add_index :seeds, :source
  end
end
