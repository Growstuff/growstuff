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

    it "assigns a new @order_item to build forms" do
      get :index, {}
      assigns(:order_item).should be_an_instance_of OrderItem
    end

    it "assigns @order as nil if the user doesn't have one" do
      get :index, {}
      assigns(:order).should be_nil
    end

    it "assigns @order as current_order if there is one" do
      @member = FactoryGirl.create(:member)
      sign_in @member
      @order = FactoryGirl.create(:order, :member => @member)
      get :index, {}
      assigns(:order).should eq @order
    end

  end

end
