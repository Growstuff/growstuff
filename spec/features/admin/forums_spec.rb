# frozen_string_literal: true

require 'rails_helper'

describe "forums", js: true do
  include_context 'signed in admin'
  let(:forum) { create :forum }

  describe "navigating to forum admin with js" do
    before do
      visit admin_path
      within 'nav#site_admin' do
        click_link "Forums"
      end
    end
    it { expect(page).to have_current_path forums_path, ignore_query: true }
    it { expect(page).to have_link "New forum" }
  end

  describe "adding a forum" do
    before do
      visit forums_path
      click_link "New forum"
      expect(page).to have_current_path new_forum_path, ignore_query: true
      fill_in 'Name', with: 'Discussion'
      fill_in 'Description', with: "this is a new forum"
      click_button 'Save'
    end
    it { expect(page).to have_current_path forum_path(Forum.last), ignore_query: true }
    it { expect(page).to have_content 'Forum was successfully created' }
  end

  describe 'editing forum' do
    before do
      visit forum_path forum
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      forum.reload
    end
    it { expect(page).to have_current_path forum_path(forum), ignore_query: true }
    it { expect(page).to have_content 'Forum was successfully updated' }
    it { expect(page).to have_content 'Something else' }
  end

  describe 'deleting forum' do
    before do
      visit forum_path forum
      accept_confirm do
        click_link 'Delete'
      end
    end
    it { expect(page).to have_current_path forums_path, ignore_query: true }
    it { expect(page).to have_content 'Forum was successfully deleted' }
  end
end
