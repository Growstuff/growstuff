# frozen_string_literal: true

require 'rails_helper'

describe 'Planting from the garden page', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }

  before do
    visit garden_path(garden)
    within('section.garden-plantings') { click_button 'add' }
  end

  it 'opens the plant dialog over the page' do
    expect(page).to have_css '[role=dialog]', text: 'Plant something in Orchard'
  end

  it 'plants the chosen crop in this garden' do
    within '[role=dialog]' do
      fill_in 'What did you plant?', with: 'lett'
      find('[role=option]', text: 'lettuce').click
      click_button 'Plant it'
    end

    expect(page).to have_css '.planting', text: 'lettuce'
  end
end
