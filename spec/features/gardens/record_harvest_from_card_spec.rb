# frozen_string_literal: true

require 'rails_helper'

describe 'Recording a harvest from a garden card', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce', median_lifespan: 100) }
  let!(:kale) { create(:annual_crop, name: 'kale') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: lettuce, planted_at: 10.days.ago) }
  let!(:leaf) { create(:plant_part, name: 'leaf') }
  let!(:root) { create(:plant_part, name: 'root') }

  before { visit gardens_path }

  # The menu shows its items in lowercase (CSS), but links are found by their text.
  def open_dialog(crop = 'lettuce')
    within('.planting-row', text: crop) do
      click_link "Actions for #{crop}"
      click_link 'Record Harvest'
    end
  end

  def choose_part(term, name)
    find_field('What part did you harvest?').send_keys(term)
    find('[role=option]', text: name).click
  end

  it 'opens a dialog over the list, with the cursor in the box that completes the plant part' do
    open_dialog

    within '[role=dialog]' do
      expect(page).to have_content 'Record a harvest of lettuce'
      expect(page).to have_css '.plant-step-current', text: 'Choose a part'
      expect(page).to have_field 'What part did you harvest?', focused: true
      expect(page).to have_no_button 'Cancel'

      find_field('What part did you harvest?').send_keys('ea')
      expect(page).to have_css '[role=option]', text: 'leaf'
      expect(page).to have_no_css '[role=option]', text: 'root'
    end
    expect(page).to have_current_path(gardens_path)
  end

  it 'asks the part, how much, when and for notes, then saves without leaving the list' do
    open_dialog

    within '[role=dialog]' do
      choose_part('lea', 'leaf')

      expect(page).to have_css '.plant-step-current', text: 'How much?'
      fill_in 'How many?', with: '3'
      fill_in 'Weighing (in total)', with: '1.5'
      click_button 'Next'

      expect(page).to have_css '.plant-step-current', text: 'When?'
      expect(page).to have_css '.crop-confirm', text: '3 individual'
      click_button 'Next'

      expect(page).to have_css '.plant-step-current', text: 'Any notes?'
      fill_in 'Any notes?', with: 'First cut'
      click_button 'Save harvest'
    end

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Recorded a harvest of lettuce in Orchard.'
    expect(page).to have_css '.planting-just-harvested .harvest-recorded-tag', text: 'Harvest recorded'
    expect(page).to have_current_path(gardens_path)
    expect(Harvest.last).to have_attributes(owner: member, crop: lettuce, planting: planting, plant_part: leaf, quantity: 3,
                                            weight_quantity: 1.5, description: 'First cut', harvested_at: Time.zone.today)
  end

  it 'offers yesterday, and lets you enter a date after the planting' do
    open_dialog

    within '[role=dialog]' do
      choose_part('roo', 'root')
      click_button 'Next'
      expect(page).to have_css '.pill-choice', text: 'Today'
      expect(page).to have_css '.pill-choice', text: 'Yesterday'
      find('label', text: 'Yesterday').click
      click_button 'Next'
      click_button 'Save harvest'
    end

    expect(page).to have_content 'Recorded a harvest of lettuce'
    expect(Harvest.last).to have_attributes(plant_part: root, harvested_at: Time.zone.today - 1)
  end

  it 'does not offer yesterday for a planting made today' do
    create(:planting, garden: garden, owner: member, crop: kale, planted_at: Time.zone.today)
    visit gardens_path
    open_dialog('kale')

    within '[role=dialog]' do
      choose_part('lea', 'leaf')
      click_button 'Next'

      expect(page).to have_css '.pill-choice', text: 'Today'
      expect(page).to have_css '.pill-choice', text: 'Enter date'
      expect(page).to have_no_css '.pill-choice', text: 'Yesterday'
    end
  end

  it 'draws a tick on the planting bar for the harvest' do
    create(:harvest, planting: planting, owner: member, crop: lettuce, plant_part: leaf, harvested_at: 5.days.ago)
    visit gardens_path

    within('.planting-row', text: 'lettuce') do
      expect(page).to have_css '.harvest-tick', count: 1, visible: :all
      expect(page).to have_css '.visually-hidden', text: '1 harvest, the latest on', visible: :all
    end
  end
end
