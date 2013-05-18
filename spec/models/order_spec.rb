require 'spec_helper'

describe Order do
  before(:each) do
    @order = FactoryGirl.create(:order)
    @product = FactoryGirl.create(:product)
    @order_item = FactoryGirl.create(:order_item,
      :order_id => @order.id, :product_id => @product.id)
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
    @order = FactoryGirl.create(:order, :member => @member)
    @account_type = FactoryGirl.create(:account_type, :name => 'paid')
    @product = FactoryGirl.create(:product,
      :account_type => @account_type,
      :paid_months => 3
    )
    @order_item = FactoryGirl.create(:order_item,
      :order_id => @order.id, :product_id => @product.id)

    @member.account.account_type.should be_nil
    @member.account.paid_until.should be_nil

    @order.update_account

    @member.account.account_type.should eq @account_type
    @member.account.paid_until.should_not be_nil
  end

end
