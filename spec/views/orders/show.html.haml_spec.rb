require 'spec_helper'

describe "orders/show" do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
  end

  context "current order" do
    before(:each) do
      @order = assign(:order, FactoryGirl.create(:order, :member => @member))
      @order_item = FactoryGirl.create(:order_item,
        :order => @order,
        :quantity => 2,
        :price => 9900
      )
      render
    end

    it "displays order number" do
      rendered.should contain "Order number"
    end

    it "shows order items in a table" do
      assert_select "table>tr>th", :text => "Product"
    end

    it "shows the total" do
      rendered.should contain "Total:"
      rendered.should contain "198.00"
    end

    it "shows a checkout button" do
      assert_select "a", :text => "Checkout with PayPal"
    end

    it "shows a delete order button" do
      assert_select "a", :text => "Delete this order"
    end
  end

  context "completed order" do
    before(:each) do
      @order = assign(:order, FactoryGirl.create(:completed_order, :member => @member))
      @order_item = FactoryGirl.create(:order_item,
        :order => @order,
        :quantity => 2,
        :price => 9900
      )
      render
    end

    it "doesn't show a checkout button" do
      assert_select "a", :text => "Checkout", :count => 0
    end

    it "doesn't show delete order button" do
      assert_select "a", :text => "Delete this order", :count => 0
    end

  end

end
