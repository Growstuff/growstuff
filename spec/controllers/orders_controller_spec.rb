require 'spec_helper'

describe OrdersController do

  login_member(:admin_member)

  def valid_attributes
    { "member_id" => 1 }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all orders as @orders" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      get :index, {}
      assigns(:orders).should eq([order])
    end
  end

  describe "GET show" do
    it "assigns the requested order as @order" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      get :show, {:id => order.to_param}
      assigns(:order).should eq(order)
    end
  end
end
