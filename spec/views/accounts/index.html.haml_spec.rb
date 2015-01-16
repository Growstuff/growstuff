require 'rails_helper'

describe "accounts/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @account = @member.account
    assign(:accounts, [@account, @account])
  end

  it "renders a list of accounts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => @account.member_id.to_s, :count => 2
  end
end
