# frozen_string_literal: true

require 'rails_helper'

describe 'forums', js: true do
  include_context 'signed in admin'
  let(:forum) { create :forum }

  describe 'navigating to forum admin with js' do
    before do
      visit admin_path
      within 'nav#site_admin' do
        click_link 'Forums'
      end
    end
    it { expect(current_path).to eq forums_path }
    it { expect(page).to have_link 'New forum' }
  end

  describe 'adding a forum' do
    before do
      visit forums_path
      click_link 'New forum'
      expect(current_path).to eq new_forum_path
      fill_in 'Name', with: 'Discussion'
      fill_in 'Description', with: 'this is a new forum'
      click_button 'Save'
    end
    it { expect(current_path).to eq forum_path(Forum.last) }
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
    it { expect(current_path).to eq forum_path(forum) }
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
    it { expect(current_path).to eq forums_path }
    it { expect(page).to have_content 'Forum was successfully deleted' }
  end
end
