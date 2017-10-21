require 'rails_helper'

feature "cms admin" do
  let(:member) { create :member }
  let(:admin_member) { create :admin_member }

  scenario "can't view CMS admin if not signed in" do
    visit comfy_admin_cms_path
    expect(current_path).to eq root_path
    expect(page).to have_content "Please sign in as an admin user"
  end

  scenario "can't view CMS admin if not an admin member" do
    # sign in as an ordinary member
    login_as member
    visit comfy_admin_cms_path
    expect(current_path).to eq root_path
    expect(page).to have_content "Please sign in as an admin user"
  end

  scenario "admin members can view CMS admin area" do
    login_as admin_member
    visit comfy_admin_cms_path
    expect(current_path).to match(/#{comfy_admin_cms_path}/) # match any CMS admin page
  end
end
