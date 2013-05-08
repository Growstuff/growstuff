require 'spec_helper'

describe Order do
  before(:each) do
    @order = FactoryGirl.create(:order)
    @product = FactoryGirl.create(:product)
    @order.products << @product
  end

  it 'has products' do
    @order.products.first.should eq @product
  end

  it 'sorts by created_at DESC' do
    @order2 = FactoryGirl.create(:order)
    Order.all.should eq [@order2, @order]
  end

end
