require 'rails_helper'

describe "products/show" do
  before(:each) do
    @product = assign(:product, FactoryGirl.create(:product))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should have_content @product.name
    rendered.should have_content @product.min_price.to_s
    rendered.should have_content @product.recommended_price.to_s
  end
end
