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

describe OrderItemsController do

  login_member(:admin_member)

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    @product = FactoryGirl.create(:product)
    @order = FactoryGirl.create(:order, member: @member)
    @order_item = FactoryGirl.create(:order_item,
      order: @order,
      product: @product,
      price: @product.min_price
    )
  end

  describe "POST create" do

    it "redirects to order" do
      @order = FactoryGirl.create(:order, member: @member)
      post :create, {order_item: {
        order_id: @order.id,
        product_id: @product.id,
        price: @product.min_price
      }}
      response.should redirect_to(OrderItem.last.order)
    end

    it 'creates an order for you' do
      @member = FactoryGirl.create(:member)
      sign_in @member
      @product = FactoryGirl.create(:product)
      expect {
        post :create, {order_item: {
          product_id: @product.id,
          price: @product.min_price
        }}
      }.to change(Order, :count).by(1)
      OrderItem.last.order.should be_an_instance_of Order
    end

    describe "with non-int price" do
      it "converts 3.33 to 333 cents" do
        @order = FactoryGirl.create(:order, member: @member)
        @product = FactoryGirl.create(:product, min_price: 1)
        expect {
          post :create, {order_item: {
            order_id: @order.id,
            product_id: @product.id,
            price: 3.33
          }}
        }.to change(OrderItem, :count).by(1)
        OrderItem.last.price.should eq 333
      end
    end
  end
end
