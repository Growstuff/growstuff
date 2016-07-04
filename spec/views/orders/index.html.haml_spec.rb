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

describe "orders/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    @order1 = FactoryGirl.create(:order, member: @member)
    @order2 = FactoryGirl.create(:completed_order, member: @member)
    assign(:orders, [ @order1, @order2 ])
  end

  it "shows your current account status" do
    render
    rendered.should have_content "Your current account status"
  end

  it "renders a list of orders" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td a/@href", text: "/orders/#{@order1.id}"
    assert_select "tr>td a/@href", text: "/orders/#{@order2.id}"
  end
end
