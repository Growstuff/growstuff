require 'spec_helper'

describe AccountDetail do
  before(:each) do
    @member = FactoryGirl.create(:member)
  end

  it "auto-creates an account detail record when a member is created" do
    @member.account_detail.should be_an_instance_of AccountDetail
  end

  it "won't let you create two account details for the same member" do
    @details = AccountDetail.new(:member_id => @member.id)
    @details.should_not be_valid
  end
end
