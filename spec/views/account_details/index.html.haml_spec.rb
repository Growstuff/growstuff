require 'spec_helper'

describe "account_details/index" do
  before(:each) do
    assign(:account_details, [
      stub_model(AccountDetail,
        :member_id => 1,
        :account_type => 1
      ),
      stub_model(AccountDetail,
        :member_id => 1,
        :account_type => 1
      )
    ])
  end

  it "renders a list of account_details" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Account Type".to_s, :count => 2
  end
end
