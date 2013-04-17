require 'spec_helper'

describe "notifications/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
    @notification = FactoryGirl.create(:notification, :sender => @member, :recipient => @member)
    assign(:notifications, [ @notification, @notification ])
    render
  end

  it "renders a list of notifications" do
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "table"
    assert_select "tr>td", :text => @notification.sender.to_s, :count => 2
    assert_select "tr>td", :text => @notification.subject, :count => 2
  end

  it "links to sender's profile" do
    assert_select "a", :href => member_path(@notification.sender)
  end
end
