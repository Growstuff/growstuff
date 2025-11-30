# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Reverting crops' do
  let(:admin) { create(:member, :admin) }
  let(:member) { create(:member) }
  let!(:crop) { create(:crop, name: 'Initial Name') }

  before do
    crop.update(name: 'Updated Name')
  end

  context 'when logged in as an admin' do
    before do
      login_as(admin, scope: :member)
    end

    scenario 'Admin reverts a crop' do
      visit admin_crops_path
      click_link 'Revert'
      expect(page).to have_content('Reverted to version from')
      crop.reload
      expect(crop.name).to eq('Initial Name')
    end
  end

  context 'when logged in as a regular member' do
    before do
      login_as(member, scope: :member)
    end

    scenario 'Member cannot revert a crop' do
      visit admin_crops_path
      expect(page).not_to have_link('Revert')

      # Also check that they can't access the revert path directly
      page.driver.post(revert_admin_version_path(crop.versions.last))
      expect(page).to have_content('You are not authorized to access this page')
    end
  end
end
