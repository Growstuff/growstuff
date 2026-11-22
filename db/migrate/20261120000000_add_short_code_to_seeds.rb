# frozen_string_literal: true

# Existing seed packets keep a null code until they are next saved.
class AddShortCodeToSeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :seeds, :short_code, :string, limit: 10
    add_index :seeds, %i(owner_id short_code), unique: true
  end
end
