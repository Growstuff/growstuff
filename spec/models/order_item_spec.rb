require 'rails_helper'

describe OrderItem do

  let(:order_item) { FactoryGirl.create(:order_item) }

  it "has an order and a product" do
    order_item.order.should be_an_instance_of Order
    order_item.product.should be_an_instance_of Product
  end

  it "validates price > product.min_price" do
    @product = FactoryGirl.create(:product)
    order_item = FactoryGirl.build(:order_item, price: @product.min_price - 1)
    order_item.should_not be_valid
  end

  it "doesn't let you add two items to an order" do
    @product = FactoryGirl.create(:product)
    @order = FactoryGirl.create(:order)
    order_item = FactoryGirl.build(:order_item, order: @order)
    order_item.should be_valid
    order_item.save
    @order_item2 = FactoryGirl.build(:order_item, order: @order)
    @order_item2.should_not be_valid
  end

end
