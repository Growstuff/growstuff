require 'spec_helper'

describe OrdersController do

  login_member(:admin_member)

  def valid_attributes
    { "member_id" => "MyString" }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all orders as @orders" do
      order = Order.create! valid_attributes
      get :index, {}
      assigns(:orders).should eq([order])
    end
  end

  describe "GET show" do
    it "assigns the requested order as @order" do
      order = Order.create! valid_attributes
      get :show, {:id => order.to_param}
      assigns(:order).should eq(order)
    end
  end
end
