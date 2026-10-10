# frozen_string_literal: true

require 'rails_helper'

describe 'Editing a garden from its card', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard', description: 'Apples', area: 12, area_unit: 'square metre') }
  let!(:type) { create(:garden_type, name: 'Balcony') }

  before { visit gardens_path }

  def open_dialog
    within('.garden-card-header', text: 'Orchard') do
      click_link 'Actions for Orchard'
      click_link 'Edit'
    end
  end

  it 'opens a dialog over the list with the garden filled in' do
    open_dialog

    within '[role=dialog]' do
      expect(page).to have_content 'Edit Orchard'
      expect(page).to have_field 'Name', with: 'Orchard'
      expect(page).to have_field 'Description', with: 'Apples'
      expect(page).to have_field 'Area', with: '12.0'
      expect(page).to have_select 'Area unit', selected: 'square metres'
      expect(page).to have_checked_field 'Active?'
      expect(page).to have_no_button 'Cancel'
    end
    expect(page).to have_current_path(gardens_path)
  end

  it 'saves the changes, and the card shows them, without leaving the list' do
    open_dialog

    within '[role=dialog]' do
      fill_in 'Name', with: 'Back orchard'
      fill_in 'Description', with: 'Apples and pears'
      select 'Balcony', from: 'Garden type'
      click_button 'Save garden'
    end

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Saved changes to Back orchard.'
    expect(page).to have_css '.garden-card-title', text: 'Back orchard'
    expect(page).to have_current_path(gardens_path)
    expect(garden.reload).to have_attributes(name: 'Back orchard', description: 'Apples and pears', garden_type: type)
  end

  it 'says what is wrong, and keeps the dialog, when the garden cannot be saved' do
    create(:garden, owner: member, name: 'Taken')
    visit gardens_path
    open_dialog

    within '[role=dialog]' do
      fill_in 'Name', with: 'Taken'
      click_button 'Save garden'

      expect(page).to have_content 'That didn’t save'
      expect(page).to have_content 'Name has already been taken'
      expect(page).to have_field 'Name', with: 'Taken'
    end
    expect(garden.reload.name).to eq 'Orchard'
  end

  it 'takes a garden marked inactive off the list, and says where it went' do
    create(:planting, garden: garden, owner: member)
    open_dialog

    within '[role=dialog]' do
      uncheck 'Active?'
      click_button 'Save garden'
    end

    expect(page).to have_content 'Orchard is now inactive, and its plantings are finished.'
    expect(page).to have_no_css '.garden-card-title', text: 'Orchard'
    expect(garden.reload.active).to be false
    expect(garden.plantings.reload).to all(be_finished)
  end
end
