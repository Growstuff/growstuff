require 'spec_helper'

describe "orders/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    @order1 = FactoryGirl.create(:order)
    @order2 = FactoryGirl.create(:completed_order)
    assign(:orders, [ @order1, @order2 ])
  end

  it "renders a list of orders" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => @order1.id
    assert_select "tr>td", :text => @order2.id
  end
end
