require 'rails_helper'

describe "accounts/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @account = assign(:account, @member.account)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should have_content @account.member_id.to_s
    rendered.should have_content 'Free'
    rendered.should have_content @account.paid_until.to_s
  end
end
