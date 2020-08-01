# frozen_string_literal: true

class MissingUniqueness < ActiveRecord::Migration[6.0]
  def change
    add_index(:garden_types, [:name], unique: true)
    add_index(:garden_types, [:slug], unique: true)
  end
end
