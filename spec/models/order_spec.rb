require 'rails_helper'

describe Order do
  before(:each) do
    @order = FactoryGirl.create(:order)
    @product = FactoryGirl.create(:product)
    @order_item = FactoryGirl.create(:order_item,
      order_id: @order.id, product_id: @product.id)
  end

  it 'has order_items' do
    @order.order_items.first.should eq @order_item
  end

  it 'sorts by created_at DESC' do
    @order2 = FactoryGirl.create(:order)
    Order.all.should eq [@order2, @order]
  end

  it 'updates the account details' do
    @member = FactoryGirl.create(:member)
    @order = FactoryGirl.create(:order, member: @member)
    @account_type = FactoryGirl.create(:account_type, name: 'paid')
    @product = FactoryGirl.create(:product,
      account_type: @account_type,
      paid_months: 3
    )
    @order_item = FactoryGirl.create(:order_item,
      order_id: @order.id, product_id: @product.id)

    @member.account.paid_until.should be_nil

    @order.update_account

    @member.account.account_type.should eq @account_type
    @member.account.paid_until.should_not be_nil
  end

  it "totals the amount due" do
    @member = FactoryGirl.create(:member)
    @order = FactoryGirl.create(:order, member: @member)
    @product = FactoryGirl.create(:product,
      min_price: 1000
    )
    # we force an order to only have one item at present. Add more if wanted
    # later.
    @order_item1 = FactoryGirl.create(:order_item,
      order_id: @order.id, product_id: @product.id, price: 1111, quantity: 1)

    @order.total.should eq 1111 
  end

  it "gives the correct total for quantities more than 1" do
    @member = FactoryGirl.create(:member)
    @order = FactoryGirl.create(:order, member: @member)
    @product = FactoryGirl.create(:product,
      min_price: 1000
    )
    # we force an order to only have one item at present. Add more if wanted
    # later.
    @order_item1 = FactoryGirl.create(:order_item,
      order_id: @order.id, product_id: @product.id, price: 1111, quantity: 2)

    @order.total.should eq 2222 
  end

  it "formats order items for activemerchant" do
    @member = FactoryGirl.create(:member)
    @order = FactoryGirl.create(:order, member: @member)
    @product = FactoryGirl.create(:product,
      name: 'foo',
      min_price: 1000
    )
    # we force an order to only have one item at present. Add more if wanted
    # later.
    @order_item1 = FactoryGirl.create(:order_item,
      order_id: @order.id, product_id: @product.id, price: 1111, quantity: 1)

    @order.activemerchant_items.should eq [{
      name: 'foo',
      quantity: 1,
      amount: 1111
    }]

  end

  context "referral codes" do
    it "has a referral code" do
      referred_order = FactoryGirl.create(:referred_order)
      referred_order.referral_code.should_not be nil
    end

    it "validates referral codes" do
      referred_order = FactoryGirl.build(:order, referral_code: 'CAMP_AIGN1?')
      referred_order.should_not be_valid
    end

    it "cleans up messy referral codes" do
      referred_order = FactoryGirl.create(:order, referral_code: 'CaMpAiGn 1  ')
      referred_order.referral_code.should eq 'CAMPAIGN1'
    end
  end

  context 'search' do
    it 'finds orders by member' do
      order = FactoryGirl.create(:order)
      Order.search(by: 'member', for: order.member.login_name).should eq [order]
    end

    it 'finds orders by order_id' do
      order = FactoryGirl.create(:order)
      Order.search(by: 'order_id', for: order.id).should eq [order]
    end

    it 'finds orders by paypal_token' do
      order = FactoryGirl.create(:order, paypal_express_token: 'foo')
      Order.search(by: 'paypal_token', for: 'foo').should eq [order]
    end

    it 'finds orders by paypal_payer_id' do
      order = FactoryGirl.create(:order, paypal_express_payer_id: 'bar')
      Order.search(by: 'paypal_payer_id', for: 'bar').should eq [order]
    end

    it 'finds orders by referral_code' do
      order = FactoryGirl.create(:order, referral_code: 'baz')
      Order.search(by: 'referral_code', for: 'baz').should eq [order]
    end

  end

end
