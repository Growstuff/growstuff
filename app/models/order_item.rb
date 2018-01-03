class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validate :price_must_be_greater_than_minimum
  validates :order_id, uniqueness: { message: "may only have one item." }

  def price_must_be_greater_than_minimum
    @product = Product.find(product_id)
    errors.add(:price, "must be greater than the product's minimum value") if price < @product.min_price
  end
end
