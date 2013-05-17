require 'spec_helper'

describe "account_details/show" do
  before(:each) do
    @account_detail = assign(:account_detail,
        FactoryGirl.create(:account_detail)
    )
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should contain @account_detail.member_id.to_s
    rendered.should contain @account_detail.account_type.name
    rendered.should contain @account_detail.paid_until.to_s
  end
end
