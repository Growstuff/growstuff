require 'spec_helper'

describe "orders/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @order = assign(:order, FactoryGirl.create(:order, :member => @member))
    @order_item = FactoryGirl.create(:order_item,
      :order => @order,
      :quantity => 2,
      :price => 99.00
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

end
