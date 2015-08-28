require 'rails_helper'

feature "account types", :js => true do
  context "admin user" do
    let(:member) { create :admin_member }
    let(:account_type) { create :account_type }

    background do
      login_as member
    end

    scenario "navigating to account type admin with JavaScript on" do
      visit root_path
      # Extra click for the expandable login menu
      click_link member.login_name
      click_link "Admin"
      expect(current_path).to eq admin_path
      click_link "Account types"
      expect(current_path).to eq account_types_path
    end

    scenario "navigating to account type admin without JavaScript - Accessility version", :js => false do
      visit root_path
      # Extra link not needed as menu is already expanded
      click_link "Admin"
      expect(current_path).to eq admin_path
      click_link "Account types"
      expect(current_path).to eq account_types_path
    end

    scenario "adding an account type" do
      visit account_types_path
      click_link "New Account type"
      expect(current_path).to eq new_account_type_path
      fill_in 'Name', with: 'Guest'
      click_button 'Save'
      expect(current_path).to eq account_type_path(AccountType.last)
      expect(page).to have_content 'Account type was successfully created'
    end

    scenario 'editing account type' do
      visit account_type_path account_type
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      expect(current_path).to eq account_type_path(account_type)
      expect(page).to have_content 'Account type was successfully updated'
      expect(page).to have_content 'Something else'
    end

    scenario 'deleting account type' do
      visit account_type_path account_type
      click_link 'Delete'
      expect(current_path).to eq account_types_path
      expect(page).to have_content 'Account type was successfully deleted'
    end
  end
end
