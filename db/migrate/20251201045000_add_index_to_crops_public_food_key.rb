# frozen_string_literal: true

class AddIndexToCropsPublicFoodKey < ActiveRecord::Migration[7.2]
  def change
    add_index :crops, :public_food_key
  end
end
