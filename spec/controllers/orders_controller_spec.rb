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

  describe "GET checkout" do
    it "redirects to Paypal" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      get :checkout, {:id => order.to_param}
      response.status.should eq 302
      response.redirect_url.should match /paypal\.com/
    end
  end

  describe "GET complete" do
    it "assigns the requested order as @order" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      get :complete, {:id => order.to_param}
      assigns(:order).should eq(order)
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested order" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      expect {
        delete :destroy, {:id => order.id}
      }.to change(Order, :count).by(-1)
    end

    it "redirects to the posts list" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(:member_id => member.id)
      delete :destroy, {:id => order.id}
      response.should redirect_to(shop_url)
    end
  end

end
