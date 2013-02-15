require 'spec_helper'

describe "notifications/index" do
  before(:each) do
    assign(:notifications, [
      stub_model(Notification,
        :from_id => 1,
        :to_id => 2,
        :subject => "Subject",
        :body => "MyText",
        :read => false,
        :post_id => 4
      ),
      stub_model(Notification,
        :from_id => 1,
        :to_id => 2,
        :subject => "Subject",
        :body => "MyText",
        :read => false,
        :post_id => 4
      )
    ])
  end

  it "renders a list of notifications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Subject".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
  end
end
