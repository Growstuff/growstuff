require 'spec_helper'

describe "account_details/index" do
  before(:each) do
    @account_detail = FactoryGirl.create(:account_detail)
    assign(:account_details, [@account_detail, @account_detail])
  end

  it "renders a list of account_details" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => @account_detail.member_id.to_s, :count => 2
  end
end
