require 'spec_helper'

describe "gardens/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @owner = FactoryGirl.create(:member)
    assign(:gardens, [
      FactoryGirl.create(:garden, :owner => @owner),
      FactoryGirl.create(:garden, :owner => @owner)
    ])
  end

  it "renders a list of gardens" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Springfield Community Garden".to_s, :count => 2
  end

end
