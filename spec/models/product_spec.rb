require 'spec_helper'

describe Product do

  it "stringifies using the name" do
    @product = FactoryGirl.create(:product)
    @product.to_s.should eq @product.name
  end
end
