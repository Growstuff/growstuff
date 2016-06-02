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

describe "orders/show" do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
  end

  context "current order" do
    before(:each) do
      @order = assign(:order, FactoryGirl.create(:order, member: @member))
      @order_item = FactoryGirl.create(:order_item,
        order: @order,
        quantity: 2,
        price: 9900
      )
      render
    end

    it "displays order number" do
      rendered.should have_content "Order number"
    end

    it "shows order items in a table" do
      assert_select "table>tr>th", text: "Product"
    end

    it "shows the total" do
      rendered.should have_content "Total:"
      assert_select "strong", /198.00/
    end

    it "shows a foreign exchange link for the total" do
      currency = Growstuff::Application.config.currency
      assert_select("a[href='http://www.wolframalpha.com/input/?i=198.00+#{currency}']")
    end

    it "asks for a referral code" do
      assert_select "input[id='referral_code']"
    end

    it "shows a checkout button" do
      assert_select "input[value='Checkout with PayPal']"
    end

    it "shows a delete order button" do
      assert_select "a", text: "Delete this order"
    end
  end

  context "completed order" do
    before(:each) do
      @order = assign(:order, FactoryGirl.create(:completed_order, member: @member))
      @order_item = FactoryGirl.create(:order_item,
        order: @order,
        quantity: 2,
        price: 9900
      )
      render
    end

    it "doesn't show a checkout button" do
      assert_select "a", text: "Checkout", count: 0
    end

    it "doesn't show delete order button" do
      assert_select "a", text: "Delete this order", count: 0
    end

  end

end
