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

describe 'admin/index.html.haml', type: "view" do
  before(:each) do
    @member = FactoryGirl.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    render
  end

  it "includes links to manage various things" do
    assert_select "a", href: account_types_path
    assert_select "a", href: products_path
    assert_select "a", href: roles_path
    assert_select "a", href: forums_path
  end

  it "has a link to newsletter subscribers" do
    rendered.should have_content "Newsletter subscribers"
  end
end
