# frozen_string_literal: true

require 'rails_helper'

describe 'Noting an observation on a planting', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: lettuce, planted_at: 10.days.ago) }

  def choose_kind_and_save(kind, note)
    within '[role=dialog]' do
      expect(page).to have_content 'Add observation to lettuce'
      expect(page).to have_button 'Add observation', disabled: true
      find('label', text: kind).click
      fill_in 'Note', with: note
      click_button 'Add observation'
    end
  end

  context 'from a garden card' do
    before do
      visit_gardens_open
      open_all_gardens
    end

    it 'adds it without leaving the list' do
      within('.planting-row', text: 'lettuce') do
        click_link 'Actions for lettuce'
        click_link 'Add observation'
      end
      choose_kind_and_save('Wilting', 'Droopy by noon')

      expect(page).to have_no_css '[role=dialog]'
      expect(page).to have_content 'Added an observation to lettuce.'
      expect(page).to have_current_path(gardens_path)
      expect(planting.observations.last).to have_attributes(kind: 'wilting', description: 'Droopy by noon', author: member)
    end
  end

  context 'from the planting page' do
    before { visit planting_path(planting) }

    it 'adds it to the timeline from the section heading' do
      within('#observations') { click_link 'add' }
      choose_kind_and_save('Flowering', 'First blossoms')

      expect(page).to have_css '#observations .observation', text: 'Flowering'
      expect(page).to have_css '#observations .observation', text: 'First blossoms'
      expect(page).to have_css '#observations .observation-day', text: 'Day 10'
    end

    it 'edits one from the timeline' do
      create(:observation, planting: planting, kind: 'fruiting', description: 'Green ones')
      visit planting_path(planting)

      find('#observations .observation-edit').click
      within '[role=dialog]' do
        expect(page).to have_content 'Edit observation of lettuce'
        expect(page).to have_checked_field 'Fruiting', visible: :all
        find('label', text: 'Other').click
        fill_in 'Note', with: 'Strange ones'
        click_button 'Save changes'
      end

      expect(page).to have_css '#observations .observation-kind', text: 'Other'
      expect(page).to have_css '#observations .observation', text: 'Strange ones'
      expect(planting.observations.last).to have_attributes(kind: nil, description: 'Strange ones')
    end

    it 'removes one from the timeline' do
      create(:observation, planting: planting, kind: 'fruiting')
      visit planting_path(planting)

      accept_confirm { find('#observations .observation-delete').click }

      expect(page).to have_content 'Observation deleted.'
      expect(page).to have_no_css '#observations .observation'
    end
  end
end
