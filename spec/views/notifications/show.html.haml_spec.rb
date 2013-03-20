require 'spec_helper'

describe "notifications/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @notification = FactoryGirl.create(:notification, :recipient => @member)
    assign(:notification, @notification)
    controller.stub(:current_user) { @member }
    render
  end

  it "renders attributes" do
    rendered.should contain @notification.sender.to_s
    rendered.should contain @notification.body.to_s
  end

  it "includes a delete button" do
    assert_select "a", "Delete notification"
  end

end
