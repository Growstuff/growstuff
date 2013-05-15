require 'spec_helper'

describe OrderItem do
  before(:each) do
    @order_item = FactoryGirl.create(:order_item)
  end

  it "has an order and a product" do
    @order_item.order.should be_an_instance_of Order
    @order_item.product.should be_an_instance_of Product
  end

end
