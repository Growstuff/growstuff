require 'spec_helper'

describe Order do
  before(:each) do
    @order = FactoryGirl.create(:order)
    @product = FactoryGirl.create(:product)
    @order_item = FactoryGirl.create(:order_item,
      :order_id => @order.id, :product_id => @product.id)
  end

  it 'has order_items' do
    @order.order_items.first.should eq @order_item
  end

  it 'sorts by created_at DESC' do
    @order2 = FactoryGirl.create(:order)
    Order.all.should eq [@order2, @order]
  end

end
