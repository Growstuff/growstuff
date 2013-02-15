require 'spec_helper'

describe "notifications/new" do
  before(:each) do
    assign(:notification, stub_model(Notification,
      :from_id => 1,
      :to_id => 1,
      :subject => "MyString",
      :body => "MyText",
      :read => false,
      :post_id => 1
    ).as_new_record)
  end

  it "renders new notification form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => notifications_path, :method => "post" do
      assert_select "input#notification_from_id", :name => "notification[from_id]"
      assert_select "input#notification_to_id", :name => "notification[to_id]"
      assert_select "input#notification_subject", :name => "notification[subject]"
      assert_select "textarea#notification_body", :name => "notification[body]"
      assert_select "input#notification_read", :name => "notification[read]"
      assert_select "input#notification_post_id", :name => "notification[post_id]"
    end
  end
end
