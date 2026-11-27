# frozen_string_literal: true

class AddAlignmentToDomesticatedAnimals < ActiveRecord::Migration[8.1]
  def change
    add_column :domesticated_animals, :alignment, :string
  end
end
