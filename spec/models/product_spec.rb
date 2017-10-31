require 'rails_helper'

describe Product do
  it "stringifies using the name" do
    @product = FactoryBot.create(:product)
    @product.to_s.should eq @product.name
  end
end
