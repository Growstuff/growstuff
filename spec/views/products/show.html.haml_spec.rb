require 'spec_helper'

describe "products/show" do
  before(:each) do
    @product = assign(:product, FactoryGirl.create(:product))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should contain @product.name
    rendered.should contain @product.description
    rendered.should contain @product.min_price.to_s
  end
end
