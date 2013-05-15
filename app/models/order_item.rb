class OrderItem < ActiveRecord::Base
  attr_accessible :order_id, :price, :product_id, :quantity

  belongs_to :order
  belongs_to :product

  validate :price_must_be_greater_than_minimum

  def price_must_be_greater_than_minimum
    @product = Product.find(product)
    if price < @product.min_price
      errors.add(:discount, "must be greater than the product's minimum value")
    end
  end
end
