require 'rails_helper'

describe Account do

  let(:member) { FactoryGirl.create(:member) }

  it "auto-creates an account detail record when a member is created" do
    member.account.should be_an_instance_of Account
  end

  it "won't let you create two account details for the same member" do
    @details = Account.new(member_id: member.id)
    @details.should_not be_valid
  end

  it "formats the 'paid until' date nicely" do
    member.account.account_type = FactoryGirl.create(:account_type)
    member.account.paid_until_string.should eq nil

    member.account.account_type = FactoryGirl.create(:permanent_paid_account_type)
    member.account.paid_until_string.should eq "forever"

    member.account.account_type = FactoryGirl.create(:paid_account_type)
    @time = Time.zone.now
    member.account.paid_until = @time
    member.account.paid_until_string.should eq @time.to_s
  end

end
