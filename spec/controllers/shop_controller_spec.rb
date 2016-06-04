## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

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
      @order = FactoryGirl.create(:order, member: @member)
      get :index, {}
      assigns(:order).should eq @order
    end

  end

end
