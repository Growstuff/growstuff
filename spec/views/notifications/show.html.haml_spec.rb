require 'rails_helper'

describe "notifications/show" do
  before(:each) do
    @member = FactoryBot.create(:member)
    @notification = FactoryBot.create(:notification, recipient: @member)
    assign(:notification, @notification)
    @reply_link = assign(:reply_link, new_notification_path)
    controller.stub(:current_user) { @member }
    render
  end

  it "renders attributes" do
    rendered.should have_content @notification.sender.to_s
    rendered.should have_content @notification.body.to_s
  end

  it "includes a delete button" do
    assert_select "a", "Delete"
  end

  it "includes a reply button" do
    assert_select "a", { href: @reply_link }, "Reply"
  end
end
