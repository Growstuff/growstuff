class AddRecommendedPriceToProduct < ActiveRecord::Migration
  def change
    add_column :products, :recommended_price, :integer
  end
end
