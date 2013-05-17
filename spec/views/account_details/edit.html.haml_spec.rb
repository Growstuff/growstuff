require 'spec_helper'

describe "account_details/edit" do
  before(:each) do
    @account_detail = assign(:account_detail,
        FactoryGirl.create(:account_detail)
    )
  end

  it "renders the edit account_detail form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => account_details_path(@account_detail), :method => "post" do
      assert_select "input#account_detail_member_id", :name => "account_detail[member_id]"
      assert_select "input#account_detail_account_type", :name => "account_detail[account_type]"
    end
  end
end
