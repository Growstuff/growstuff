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

describe 'admin/newsletter.html.haml', type: "view" do
  before(:each) do
    @member = FactoryGirl.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @subscriber = FactoryGirl.create(:newsletter_recipient_member)
    assign(:members, [@subscriber])
    render
  end

  it "lists newsletter subscribers by email" do
    rendered.should have_content @subscriber.email
  end
end
