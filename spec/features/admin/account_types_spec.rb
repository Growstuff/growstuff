require 'rails_helper'

feature "account types" do
  context "admin user" do
    let(:member) { FactoryGirl.create(:admin_member) }

    background do
      login_as member
    end

    scenario "navigating to account type admin" do
      visit root_path
      click_link "Admin"
      current_path.should eq admin_path
      click_link "Account types"
      current_path.should eq account_types_path
    end

    scenario "adding an account type" do
      visit account_types_path
      click_link "New Account type"
      current_path.should eq new_account_type_path
      fill_in 'Name', :with => 'Guest'
      click_button 'Save'
      current_path.should eq account_type_path(AccountType.last)
      page.should have_content 'Account type was successfully created'
    end

    scenario 'editing account type' do
      a = FactoryGirl.create(:account_type)
      visit account_type_path(a)
      click_link 'Edit'
      fill_in 'Name', :with => 'Something else'
      click_button 'Save'
      current_path.should eq account_type_path(a)
      page.should have_content 'Account type was successfully updated'
      page.should have_content 'Something else'
    end

    scenario 'deleting account type' do
      a = FactoryGirl.create(:account_type)
      visit account_type_path(a)
      click_link 'Delete'
      current_path.should eq account_types_path
      page.should have_content 'Account type was successfully deleted'
    end
  end
end
