require 'spec_helper'

describe "notifications/show" do
  before(:each) do
    @notification = assign(:notification, stub_model(Notification,
      :from_id => 1,
      :to_id => 2,
      :subject => "Subject",
      :body => "MyText",
      :read => false,
      :post_id => 4
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/Subject/)
    rendered.should match(/MyText/)
    rendered.should match(/false/)
    rendered.should match(/4/)
  end
end
