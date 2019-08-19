require 'rails_helper'

describe "forums", js: true do
  context "as an admin user" do
    let(:member) { create :admin_member }
    let(:forum)  { create :forum        }

    before do
      login_as member
    end

    it "navigating to forum admin with js" do
      visit admin_path
      within 'nav#site_admin' do
        click_link "Forums"
      end
      expect(current_path).to eq forums_path
      expect(page).to have_link "New forum"
    end

    it "adding a forum" do
      visit forums_path
      click_link "New forum"
      expect(current_path).to eq new_forum_path
      fill_in 'Name', with: 'Discussion'
      fill_in 'Description', with: "this is a new forum"
      click_button 'Save'
      expect(current_path).to eq forum_path(Forum.last)
      expect(page).to have_content 'Forum was successfully created'
    end

    it 'editing forum' do
      visit forum_path forum
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      forum.reload
      expect(current_path).to eq forum_path(forum)
      expect(page).to have_content 'Forum was successfully updated'
      expect(page).to have_content 'Something else'
    end

    it 'deleting forum' do
      visit forum_path forum
      accept_confirm do
        click_link 'Delete'
      end
      expect(current_path).to eq forums_path
      expect(page).to have_content 'Forum was successfully deleted'
    end
  end
end
