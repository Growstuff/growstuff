require 'rails_helper'

describe "accounts/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    assign(:account, @member.account)
  end

  it "renders new account form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => accounts_path, :method => "post" do
      assert_select "input#account_member_id", :name => "account[member_id]"
      assert_select "input#account_account_type", :name => "account[account_type]"
    end
  end
end
