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

end
