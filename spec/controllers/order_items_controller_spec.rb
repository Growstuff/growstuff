require 'rails_helper'

describe OrderItemsController do

  login_member(:admin_member)

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    @product = FactoryGirl.create(:product)
    @order = FactoryGirl.create(:order, :member => @member)
    @order_item = FactoryGirl.create(:order_item,
      :order => @order,
      :product => @product,
      :price => @product.min_price
    )
  end

  describe "POST create" do

    it "redirects to order" do
      @order = FactoryGirl.create(:order, :member => @member)
      post :create, {:order_item => {
        :order_id => @order.id,
        :product_id => @product.id,
        :price => @product.min_price
      }}
      response.should redirect_to(OrderItem.last.order)
    end

    it 'creates an order for you' do
      @member = FactoryGirl.create(:member)
      sign_in @member
      @product = FactoryGirl.create(:product)
      expect {
        post :create, {:order_item => {
          :product_id => @product.id,
          :price => @product.min_price
        }}
      }.to change(Order, :count).by(1)
      OrderItem.last.order.should be_an_instance_of Order
    end

    describe "with non-int price" do
      it "converts 3.33 to 333 cents" do
        @order = FactoryGirl.create(:order, :member => @member)
        @product = FactoryGirl.create(:product, :min_price => 1)
        expect {
          post :create, {:order_item => {
            :order_id => @order.id,
            :product_id => @product.id,
            :price => 3.33
          }}
        }.to change(OrderItem, :count).by(1)
        OrderItem.last.price.should eq 333
      end
    end
  end
end
