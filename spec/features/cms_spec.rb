# frozen_string_literal: true

require 'rails_helper'

describe "cms admin" do
  it "can't view CMS admin if not signed in" do
    visit comfy_admin_cms_path
    expect(page).to have_current_path root_path, ignore_query: true
    expect(page).to have_content "Please sign in as an admin user"
  end

  context 'signed in' do
    include_context 'signed in member'
    it "can't view CMS admin if not an admin member" do
      visit comfy_admin_cms_path
      expect(page).to have_current_path root_path, ignore_query: true
      expect(page).to have_content "Please sign in as an admin user"
    end
  end
  context 'admin' do
    include_context 'signed in admin'
    it "admin members can view CMS admin area" do
      visit comfy_admin_cms_path
      expect(page).to have_current_path(/#{comfy_admin_cms_path}/) # match any CMS admin page
    end
  end
end
