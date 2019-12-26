# frozen_string_literal: true

class AddRecommendedPriceToProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :recommended_price, :integer
  end
end
