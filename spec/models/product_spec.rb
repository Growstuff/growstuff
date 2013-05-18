require 'spec_helper'

describe Product do

  it "stringifies using the name" do
    @product = FactoryGirl.create(:product)
    @product.to_s.should eq @product.name
  end

  context "update account" do
    before(:each) do
      @product = FactoryGirl.create(:product,
        :paid_months => 3
      )
      @member = FactoryGirl.create(:member)
    end

    it "sets account_type" do
      @product.update_account(@member)
      @member.account.account_type.should eq @product.account_type
    end

    it "sets paid_until" do
      @member.account.paid_until = nil # blank for now, as if never paid before
      @product.update_account(@member)

      # stringify to avoid millisecond problems...
      @member.account.paid_until.to_s.should eq (Time.zone.now + 3.months).to_s

      # and again to make sure it works for currently paid accounts
      @product.update_account(@member)
      @member.account.paid_until.to_s.should eq (Time.zone.now + 6.months).to_s
    end
  end
end
