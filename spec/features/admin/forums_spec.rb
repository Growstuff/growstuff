require 'rails_helper'

feature "forums", js: true do
  context "as an admin user" do
    let(:member) { create :admin_member }
    let(:forum) { create :forum }

    background do
      login_as member
    end

    scenario "navigating to forum admin without js", js: false do
      visit root_path
      click_link "Admin"
      expect(current_path).to eq admin_path
      within 'ul#site_admin' do
        click_link "Forums"
      end
      expect(current_path).to eq forums_path
      expect(page).to have_content "New forum"
    end

    scenario "navigating to forum admin with js" do
      visit root_path
      click_link member.login_name
      click_link "Admin"
      expect(current_path).to eq admin_path
      within 'ul#site_admin' do
        click_link "Forums"
      end
      expect(current_path).to eq forums_path
      expect(page).to have_content "New forum"
    end

    scenario "adding a forum" do
      visit forums_path
      click_link "New forum"
      expect(current_path).to eq new_forum_path
      fill_in 'Name', with: 'Discussion'
      fill_in 'Description', with: "this is a new forum"
      click_button 'Save'
      expect(current_path).to eq forum_path(Forum.last)
      expect(page).to have_content 'Forum was successfully created'
    end

    scenario 'editing forum' do
      visit forum_path forum
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      forum.reload
      expect(current_path).to eq forum_path(forum)
      expect(page).to have_content 'Forum was successfully updated'
      expect(page).to have_content 'Something else'
    end

    scenario 'deleting forum' do
      visit forum_path forum
      click_link 'Delete'
      expect(current_path).to eq forums_path
      expect(page).to have_content 'Forum was successfully deleted'
    end
  end
end
