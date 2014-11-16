require 'rails_helper'

feature "forums" do
  context "admin user" do
    before(:each) do
      @member = FactoryGirl.create(:admin_member)
      visit root_path
      click_link 'Sign in'
      fill_in 'Login', :with => @member.login_name
      fill_in 'Password', :with => @member.password
      click_button 'Sign in'
    end

    scenario "navigating to forum admin" do
      visit root_path
      click_link "Admin"
      current_path.should eq admin_path
      within 'ul#admin_links' do
        click_link "Forums"
      end
      current_path.should eq forums_path
      page.should have_content "New forum"
    end

    scenario "adding a forum" do
      visit forums_path
      click_link "New forum"
      current_path.should eq new_forum_path
      fill_in 'Name', :with => 'Discussion'
      fill_in 'Description', :with => "this is a new forum"
      click_button 'Save'
      current_path.should eq forum_path(Forum.last)
      page.should have_content 'Forum was successfully created'
    end

    scenario 'editing forum' do
      f = FactoryGirl.create(:forum)
      visit forum_path(f)
      click_link 'Edit'
      fill_in 'Name', :with => 'Something else'
      click_button 'Save'
      f.reload
      current_path.should eq forum_path(f)
      page.should have_content 'Forum was successfully updated'
      page.should have_content 'Something else'
    end

    scenario 'deleting forum' do
      f = FactoryGirl.create(:forum)
      visit forum_path(f)
      click_link 'Delete'
      current_path.should eq forums_path
      page.should have_content 'Forum was successfully deleted'
    end
  end
end
