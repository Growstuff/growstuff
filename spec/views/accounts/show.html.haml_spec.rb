require 'spec_helper'

describe "accounts/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @account = assign(:account, @member.account)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should contain @account.member_id.to_s
    rendered.should contain 'Free account'
    rendered.should contain @account.paid_until.to_s
  end
end
