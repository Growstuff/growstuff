# frozen_string_literal: true

require 'rails_helper'

describe "roles", :js do
  include_context 'signed in admin'

  let(:role) { create(:role) }

  describe "navigating to roles admin with js" do
    before do
      visit admin_path
      within 'nav#site_admin' do
        click_link "Roles"
      end
    end

    it { expect(page).to have_current_path admin_roles_path, ignore_query: true }
    it { expect(page).to have_link "New role" }
  end

  describe "adding a role" do
    before do
      visit admin_roles_path
      click_link "New role"
      expect(page).to have_current_path new_admin_role_path, ignore_query: true
      fill_in 'Name', with: 'Discussion'
      fill_in 'Description', with: "this is a new role"
      click_button 'Save'
    end

    it { expect(page).to have_current_path admin_roles_path, ignore_query: true }
    it { expect(page).to have_content 'Role was successfully created' }
  end

  describe 'editing role' do
    before do
      @role = role
      visit admin_roles_path
      click_link 'Edit', href: edit_admin_role_path(@role)
      fill_in 'Description', with: 'Something else'
      click_button 'Save'
      role.reload
    end

    it { expect(page).to have_current_path admin_roles_path, ignore_query: true }
    it { expect(page).to have_content 'Role was successfully updated' }
    it { expect(page).to have_content 'Something else' }
  end

  describe 'deleting role' do
    before do
      @role = role
      visit admin_roles_path
      accept_confirm do
        click_link 'Delete', href: admin_role_path(@role)
      end
    end

    it { expect(page).to have_current_path admin_roles_path, ignore_query: true }
    it { expect(page).to have_content 'Role was successfully deleted' }
  end
end
