require 'spec_helper'

describe ShopController do

  before :each do
    @product1 = FactoryGirl.create(:product)
    @product2 = FactoryGirl.create(:product)
  end

  describe "GET index" do
    it "assigns all products as @products" do
      get :index, {}
      assigns(:products).should eq([@product1, @product2])
    end
  end

end
