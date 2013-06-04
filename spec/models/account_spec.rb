require 'spec_helper'

describe Account do
  before(:each) do
    @member = FactoryGirl.create(:member)
  end

  it "auto-creates an account detail record when a member is created" do
    @member.account.should be_an_instance_of Account
  end

  it "won't let you create two account details for the same member" do
    @details = Account.new(:member_id => @member.id)
    @details.should_not be_valid
  end
end
