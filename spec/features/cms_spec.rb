require 'rails_helper'

feature "cms admin" do
  
  let(:member) { FactoryGirl.create(:member) }
  let(:admin_member) { FactoryGirl.create(:admin_member) }

  scenario "can't view CMS admin if not signed in" do
    visit comfy_admin_cms_path
    current_path.should == root_path
    page.should have_content("Please sign in as an admin user")
  end

  scenario "can't view CMS admin if not an admin member" do
    # sign in as an ordinary member
    login_as member
    visit comfy_admin_cms_path
    current_path.should == root_path
    page.should have_content("Please sign in as an admin user")
  end

  scenario "admin members can view CMS admin area" do
    login_as admin_member
    visit comfy_admin_cms_path
    current_path.should match /#{comfy_admin_cms_path}/ # match any CMS admin page
  end
end
