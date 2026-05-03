# frozen_string_literal: true

class AddOverallRatingPlantings < ActiveRecord::Migration[7.2]
  def change
    add_column :plantings, :overall_rating, :integer
  end
end
