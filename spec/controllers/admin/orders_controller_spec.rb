require 'rails_helper'

describe Admin::OrdersController do
  login_member(:admin_member)

  describe "GET search" do
    it "assigns @orders" do
      order = FactoryBot.create(:order)
      get :search, search_by: 'order_id', search_text: order.id
      assigns(:orders).should eq([order])
    end

    it "sets an error message if nothing found" do
      get :search, search_by: 'order_id', search_text: 'foo'
      flash[:alert].should have_text "Couldn't find order with"
    end
  end
end
