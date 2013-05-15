require 'spec_helper'

describe OrderItem do
  before(:each) do
    @order_item = FactoryGirl.create(:order_item)
  end

  it "has an order and a product" do
    @order_item.order.should be_an_instance_of Order
    @order_item.product.should be_an_instance_of Product
  end

  it "validates price > product.min_price" do
    @product = FactoryGirl.create(:product)
    @order_item = FactoryGirl.build(:order_item, :price => @product.min_price - 1)
    @order_item.should_not be_valid
  end

end
