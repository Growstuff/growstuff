require 'spec_helper'

describe "orders/edit" do
  before(:each) do
    @order = assign(:order, stub_model(Order,
      :member_id => "MyString"
    ))
  end

  it "renders the edit order form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => orders_path(@order), :method => "post" do
      assert_select "input#order_member_id", :name => "order[member_id]"
    end
  end
end
