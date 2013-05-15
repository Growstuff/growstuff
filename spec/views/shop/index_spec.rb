require 'spec_helper'

describe 'shop/index.html.haml', :type => "view" do
  before(:each) do
    @product1 = FactoryGirl.create(:product)
    @product2 = FactoryGirl.create(:product)
    assign(:products, [@product1, @product2])
    assign(:order_item, OrderItem.new)
  end

  context "signed in" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      controller.stub(:current_user) { @member }
      render
    end

    it 'shows products' do
      assert_select("h2", :text => @product1.name)
    end

    it 'shows prices in AUD' do
      rendered.should contain '9.99 AUD'
    end

    it 'displays the order form' do
      assert_select "form", :count => 2
    end
  end

  context "signed out" do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it "tells you to sign up/sign in" do
      rendered.should contain "sign in or sign up"
    end
  end

end
