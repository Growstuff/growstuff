## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "notifications/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @notification = FactoryGirl.create(:notification, recipient: @member)
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
    assert_select "a", {href: @reply_link}, "Reply"
  end

end
