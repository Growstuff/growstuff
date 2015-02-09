require 'spec_helper'

feature "cms admin" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @admin_member = FactoryGirl.create(:admin_member)
  end

  scenario "can't view CMS admin if not signed in" do
    visit comfy_admin_cms_path
    current_path.should == root_path
    page.should have_content("Please sign in as an admin user")
  end

  scenario "can't view CMS admin if not an admin member" do
    # sign in as an ordinary member
    visit root_path
    click_link 'navbar-signin'
    fill_in 'Login', :with => @member.email
    fill_in 'Password', :with => @member.password
    click_button 'Sign in'
    visit comfy_admin_cms_path
    current_path.should == root_path
    page.should have_content("Please sign in as an admin user")
  end

  scenario "admin members can view CMS admin area" do
    visit root_path
    # now we sign in as an admin member
    click_link 'navbar-signin'
    fill_in 'Login', :with => @admin_member.email
    fill_in 'Password', :with => @admin_member.password
    click_button 'Sign in'
    visit comfy_admin_cms_path
    current_path.should match /#{comfy_admin_cms_path}/ # match any CMS admin page
  end
end
