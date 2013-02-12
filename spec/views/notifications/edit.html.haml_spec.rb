require 'spec_helper'

describe "notifications/edit" do
  before(:each) do
    @notification = assign(:notification, stub_model(Notification,
      :from_id => 1,
      :to_id => 1,
      :subject => "MyString",
      :body => "MyText",
      :read => false,
      :notification_type => 1,
      :post_id => 1
    ))
  end

  it "renders the edit notification form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => notifications_path(@notification), :method => "post" do
      assert_select "input#notification_from_id", :name => "notification[from_id]"
      assert_select "input#notification_to_id", :name => "notification[to_id]"
      assert_select "input#notification_subject", :name => "notification[subject]"
      assert_select "textarea#notification_body", :name => "notification[body]"
      assert_select "input#notification_read", :name => "notification[read]"
      assert_select "input#notification_notification_type", :name => "notification[notification_type]"
      assert_select "input#notification_post_id", :name => "notification[post_id]"
    end
  end
end
