require 'spec_helper'

describe "account_details/show" do
  before(:each) do
    @account_detail = assign(:account_detail, stub_model(AccountDetail,
      :member_id => 1,
      :account_type => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Account Type/)
  end
end
