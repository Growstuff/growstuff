require 'spec_helper'

describe 'shop/index.html.haml', :type => "view" do
  before(:each) do
    @product1 = FactoryGirl.create(:product)
    @product2 = FactoryGirl.create(:product)
    assign(:products, [@product1, @product2])
    render
  end

  it 'shows products' do
    assert_select("h2", :text => @product1.name)
  end

  it 'shows prices in AUD' do
    rendered.should contain '9.99 AUD'
  end

end
