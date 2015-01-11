require 'rails_helper'

describe "accounts/edit" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @account = assign(:account, @member.account)
  end

  it "renders the edit account form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => accounts_path(@account), :method => "post" do
      assert_select "input#account_member_id", :name => "account[member_id]"
      assert_select "input#account_account_type", :name => "account[account_type]"
    end
  end
end
