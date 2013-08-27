require 'spec_helper'

describe 'admin/newsletter.html.haml', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @subscriber = FactoryGirl.create(:newsletter_recipient_member)
    assign(:members, [@subscriber])
    render
  end

  it "lists newsletter subscribers by email" do
    rendered.should contain @subscriber.email
  end
end
