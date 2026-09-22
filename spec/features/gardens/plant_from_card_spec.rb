# frozen_string_literal: true

require 'rails_helper'

describe 'Planting from a garden card', :js, :search do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:other_garden) { create(:garden, owner: member, name: 'Balcony') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }

  before do
    Crop.reindex
    visit gardens_path
  end

  def open_plant_dialog(garden_name)
    within(:css, '.card', text: garden_name) do
      click_link 'Add planting'
    end
  end

  def search_for(term)
    fill_in 'What did you plant?', with: term
  end

  def choose_crop(name)
    search_for(name[0, 4])
    find('[role=option]', text: name).click
  end

  it 'opens a dialog over the list, asking what you planted and not which garden' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      expect(page).to have_content 'Plant something in Orchard'
      expect(page).to have_field 'What did you plant?', placeholder: 'Start typing a crop name'
      expect(page).to have_css 'img.modal-title-icon'
      expect(page).to have_css '.plant-step-current', text: 'Choose a crop'
      expect(page).to have_no_content 'Where did you plant it?'
    end
    expect(page).to have_current_path(gardens_path)
  end

  it 'shows what was chosen and plants it into that garden once confirmed, without leaving the list' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      choose_crop('lettuce')

      expect(page).to have_content 'Ready to plant?'
      expect(page).to have_css '.crop-confirm-name', text: 'lettuce'
      expect(page).to have_css '.plant-step-done', text: 'Choose a crop'
      expect(page).to have_css '.plant-step-current', text: 'Confirm'
      within('.crop-confirm') do
        expect(page).to have_content 'Garden'
        expect(page).to have_content 'Orchard'
        expect(page).to have_content 'Today'
      end
      expect(Planting.count).to eq 0

      click_button 'Plant it'
    end

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Planted lettuce in Orchard.'
    within(:css, '.card', text: 'Orchard') do
      expect(page).to have_content 'lettuce'
      # Picked out without recolouring the chip (brown with white text) it sits in.
      expect(page).to have_css '.planting-just-added', text: 'lettuce'
      # ...and the class has styling: a class with no CSS once slipped through.
      highlight = page.evaluate_script("getComputedStyle(document.querySelector('.planting-row.planting-just-added')).backgroundColor")
      expect(highlight).not_to eq 'rgba(0, 0, 0, 0)'
      expect(page).to have_no_css '.crop-chip[style]'
    end
    within(:css, '.card', text: 'Balcony') { expect(page).to have_no_content 'lettuce' }
    expect(page).to have_current_path(gardens_path)
    expect(Planting.last).to have_attributes(garden: garden, crop: lettuce, owner: member,
                                             planted_at: Time.zone.today)
  end

  it 'lets you change your mind before confirming' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      choose_crop('lettuce')
      click_button 'Change'

      expect(page).to have_field 'What did you plant?', with: ''
      expect(page).to have_no_css '.crop-confirm-name'
    end
    expect(Planting.count).to eq 0
  end

  it 'hints at typing a crop name, and offers a way to request one that is not found' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      search_for 'zzzznotacrop'

      expect(page).to have_content 'No crops match'
      expect(page).to have_link 'Request a new crop', href: new_crop_path
    end
  end

  describe 'choosing a crop with the keyboard' do
    let!(:leaf_lettuce) { create(:annual_crop, name: 'leaf lettuce') }

    before do
      Crop.reindex
      open_plant_dialog('Orchard')
      search_for 'lettuce'
      expect(page).to have_css '[role=option]', count: 2
    end

    it 'moves through the matches with the arrow keys and chooses with Enter' do
      names = all('[role=option]').map(&:text)
      crop = find_field('What did you plant?')

      crop.send_keys(:down)
      expect(page).to have_css '[role=option][aria-selected=true]', text: names[0]
      crop.send_keys(:down)
      expect(page).to have_css '[role=option][aria-selected=true]', text: names[1]
      crop.send_keys(:up)
      expect(page).to have_css '[role=option][aria-selected=true]', text: names[0]
      crop.send_keys(:enter)

      expect(page).to have_css '.crop-confirm-name', text: names[0]
      expect(page).to have_no_css '[role=option]'
      expect(Planting.count).to eq 0
    end

    it 'chooses the top match with Enter when none is highlighted' do
      names = all('[role=option]').map(&:text)

      find_field('What did you plant?').send_keys(:enter)

      expect(page).to have_css '.crop-confirm-name', text: names[0]
    end

    it 'puts focus on Plant it after choosing, so a second Enter confirms' do
      names = all('[role=option]').map(&:text)

      find_field('What did you plant?').send_keys(:down, :enter)

      expect(page).to have_css '.crop-confirm-name', text: names[0]
      expect(page.evaluate_script('document.activeElement.textContent')).to eq 'Plant it'

      find_button('Plant it').send_keys(:enter)

      expect(page).to have_content "Planted #{names[0]} in Orchard."
      expect(Planting.last.crop.name).to eq names[0]
    end

    it 'closes the list on the first Escape and the dialog on the second' do
      find_field('What did you plant?').send_keys(:escape)

      expect(page).to have_no_css '[role=option]'
      expect(page).to have_css '[role=dialog]'

      find_field('What did you plant?').send_keys(:escape)

      expect(page).to have_no_css '[role=dialog]'
    end
  end

  it 'keeps the dialog open and says what went wrong when planting fails, so you can try again' do
    allow_any_instance_of(Planting).to receive(:save) do |planting|
      planting.errors.add(:crop, 'is not available')
      false
    end
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      choose_crop('lettuce')
      click_button 'Plant it'

      expect(page).to have_css '[role=alert]', text: 'Crop is not available'
      expect(page).to have_button 'Plant it', disabled: false
    end
    expect(Planting.count).to eq 0
  end

  it 'closes with Cancel and plants nothing' do
    open_plant_dialog('Orchard')

    within('[role=dialog]') { click_button 'Cancel' }

    expect(page).to have_no_css '[role=dialog]'
    expect(Planting.count).to eq 0
  end

  it 'closes with Escape and plants nothing' do
    open_plant_dialog('Orchard')
    expect(page).to have_css '[role=dialog]'

    find_by_id('planting-crop').send_keys(:escape)

    expect(page).to have_no_css '[role=dialog]'
    expect(Planting.count).to eq 0
  end
end
