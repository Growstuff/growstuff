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

describe 'shop/index.html.haml', type: "view" do
  before(:each) do
    @product1 = FactoryGirl.create(:product)
    @product2 = FactoryGirl.create(:product_with_recommended_price)
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
      assert_select("h2", text: @product1.name)
    end

    it 'shows prices in configured currency' do
      rendered.should have_content '9.99 %s' % Growstuff::Application.config.currency
    end

    it 'should contain an exchange rate link' do
      currency = Growstuff::Application.config.currency
      assert_select("a[href='http://www.wolframalpha.com/input/?i=9.99+#{currency}']")
    end

    it 'shows recommended price for products that have it' do
      rendered.should have_content '12.00 %s' % Growstuff::Application.config.currency
    end

    it 'should contain an exchange rate link for recommended price' do
      currency = Growstuff::Application.config.currency
      assert_select("a[href='http://www.wolframalpha.com/input/?i=12.00+#{currency}']")
    end

    it 'displays the order form' do
      assert_select "form", count: 2
    end

    it 'renders markdown in product descriptions' do
      assert_select "em", text: 'hurrah', count: 2
    end
  end

  context "is paid" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      @member.account.account_type = FactoryGirl.create(:paid_account_type)
      @member.account.paid_until = Time.zone.now + 1.year
      controller.stub(:current_member) { @member }
    end

    it "recognises the paid member" do
      @member.is_paid?.should be(true)
    end

    it "tells you you have a paid membership" do
      render
      rendered.should have_content "You currently have a paid"
    end

    it "doesn't show shop" do
      render
      assert_select "form", false
    end

  end

  context "signed out" do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it "tells you to sign up/sign in" do
      rendered.should have_content "sign in or sign up"
    end
  end

end
