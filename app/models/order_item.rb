class OrderItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :product

  validate :price_must_be_greater_than_minimum

  validates_uniqueness_of :order_id, message: "may only have one item."

  def price_must_be_greater_than_minimum
    @product = Product.find(product_id)
    errors.add(:price, "must be greater than the product's minimum value") if price < @product.min_price
  end
end
