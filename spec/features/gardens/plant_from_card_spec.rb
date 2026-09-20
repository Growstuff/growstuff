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
      click_link 'Actions'
      click_link 'Plant something here'
    end
  end

  it 'opens a dialog over the list, without asking which garden' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      expect(page).to have_content 'Plant something in Orchard'
      expect(page).to have_content 'I planted'
      expect(page).to have_no_content 'Where did you plant it?'
    end
    expect(page).to have_current_path(gardens_path)
  end

  it 'plants into that garden and shows the planting on its card, without leaving the list' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      fill_in 'Quantity', with: 4
      fill_in 'Crop', with: 'lett'
      click_button 'lettuce'
      select 'seedling', from: 'Planted from'
      select 'sun', from: 'Sun or shade'
      click_button 'Save'
    end

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Planted lettuce in Orchard.'
    within(:css, '.card', text: 'Orchard') { expect(page).to have_content 'lettuce' }
    within(:css, '.card', text: 'Balcony') { expect(page).to have_no_content 'lettuce' }
    expect(page).to have_current_path(gardens_path)
    expect(Planting.last).to have_attributes(garden: garden, crop: lettuce, quantity: 4, owner: member,
                                             planted_from: 'seedling', sunniness: 'sun')
  end

  it 'keeps the dialog open and says what is wrong when no crop was chosen' do
    open_plant_dialog('Orchard')

    within '[role=dialog]' do
      click_button 'Save'

      expect(page).to have_css '[role=alert]', text: /Crop/
    end
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
