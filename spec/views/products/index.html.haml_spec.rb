require 'rails_helper'

describe "products/index" do
  before(:each) do
    @product = FactoryGirl.create(:product)
    assign(:products, [@product, @product])
  end

  it "renders a list of products" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => @product.name, :count => 2
    assert_select "tr>td", :text => @product.description, :count => 2
    assert_select "tr>td", :text => @product.min_price, :count => 2
  end
end
