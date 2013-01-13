require 'spec_helper'

describe "gardens/index" do
  before(:each) do
    @user = FactoryGirl.create(:user)
    assign(:gardens, [
      FactoryGirl.create(:garden, :user => @user),
      FactoryGirl.create(:garden, :user => @user)
    ])
  end

  it "renders a list of gardens" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "My Garden".to_s, :count => 2
  end

end
