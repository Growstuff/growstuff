# frozen_string_literal: true

require 'rails_helper'

describe 'Saving seeds from a garden card', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: lettuce, planted_at: 10.days.ago) }

  before { visit gardens_path }

  # The menu shows its items in lowercase (CSS), but links are found by their text.
  def open_dialog
    within('.planting-row', text: 'lettuce') do
      click_link 'Actions for lettuce'
      click_link 'Save seeds'
    end
  end

  def next_step
    within('[role=dialog]') { click_button 'Next' }
  end

  it 'opens a dialog over the list, with the cursor in the box asking about how many' do
    open_dialog

    within '[role=dialog]' do
      expect(page).to have_content 'Save lettuce seeds'
      expect(page).to have_css '.plant-step-current', text: 'How many?'
      expect(page).to have_field 'About how many seeds?', focused: true
      expect(page).to have_no_button 'Cancel'
    end
    expect(page).to have_current_path(gardens_path)
  end

  it 'asks how many, whether to trade them, and for notes, then saves without leaving the list' do
    open_dialog

    within '[role=dialog]' do
      fill_in 'About how many seeds?', with: '40'
      find_field('About how many seeds?').send_keys(:enter)

      expect(page).to have_css '.plant-step-current', text: 'Trade?'
      expect(page).to have_css '.crop-confirm', text: 'About 40'
      expect(page).to have_content 'They stay in your seed stash'
      find('label', text: 'Locally').click
    end
    next_step

    within '[role=dialog]' do
      expect(page).to have_css '.plant-step-current', text: 'Any notes?'
      expect(page).to have_css '.crop-confirm', text: 'Locally'
      fill_in 'Any notes?', with: 'Bolted early'
      click_button 'Save seeds'
    end

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Saved lettuce seeds to your stash.'
    expect(page).to have_link 'See them', href: seed_path(Seed.last)
    expect(page).to have_current_path(gardens_path)
    expect(Seed.last).to have_attributes(owner: member, crop: lettuce, parent_planting: planting, quantity: 40,
                                         tradable_to: 'locally', description: 'Bolted early', saved_at: Time.zone.today)
  end

  it 'takes a rough amount from a quick pick, and lets you go back and change it' do
    open_dialog

    within '[role=dialog]' do
      click_button 'About 100'
      expect(page).to have_field 'About how many seeds?', with: '100'
      click_button 'Next'
      click_button 'Change'

      expect(page).to have_css '.plant-step-current', text: 'How many?'
      expect(page).to have_field 'About how many seeds?', with: '100'
    end
  end

  it 'does not need an amount, and keeps them to yourself unless you say otherwise' do
    open_dialog
    next_step
    next_step

    within('[role=dialog]') { click_button 'Save seeds' }

    expect(page).to have_content 'Saved lettuce seeds to your stash.'
    expect(Seed.last).to have_attributes(quantity: nil, tradable_to: 'nowhere')
  end

  it 'closes with the close button, saving nothing' do
    open_dialog
    within('[role=dialog]') { click_button 'Close' }

    expect(page).to have_no_css '[role=dialog]'
    expect(Seed.count).to eq 0
  end
end
