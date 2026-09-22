# frozen_string_literal: true

require 'rails_helper'

describe 'The garden layout map', :js do
  include_context 'signed in member'

  let!(:garden)  { create(:garden, owner: member, name: 'Orchard', grid_columns: 3, grid_rows: 2) }
  let(:crop)     { create(:crop, name: 'lettuce') }
  let!(:lettuce) { create(:planting, garden:, owner: member, crop:) }

  def visit_layout
    visit layout_member_garden_path(member, garden)
  end

  it 'draws a cell for every square of the bed' do
    visit_layout

    expect(page).to have_css('.garden-layout-cell', count: 6)
  end

  it 'lists a planting that has not been placed yet' do
    visit_layout

    within '.garden-layout-tray' do
      expect(page).to have_content 'lettuce'
    end
    expect(page).to have_no_css('.garden-layout-planting')
  end

  it 'draws a placed planting over the cells it covers' do
    lettuce.update!(bed_x: 1, bed_y: 0, bed_width: 2)
    visit_layout

    expect(page).to have_css('.garden-layout-planting', text: 'lettuce')
    within '.garden-layout-tray' do
      expect(page).to have_content 'Everything is on the bed'
    end
  end

  it 'lets the owner resize the bed' do
    visit_layout
    fill_in 'Columns', with: '4'
    click_button 'Resize bed'

    expect(garden.reload.grid_columns).to eq 4
  end

  it 'will not shrink the bed past a planting, and says why' do
    lettuce.update!(bed_x: 2, bed_y: 0)
    visit_layout
    fill_in 'Columns', with: '1'
    click_button 'Resize bed'

    expect(page).to have_content 'some plantings would fall outside the bed'
    expect(garden.reload.grid_columns).to eq 3
  end

  context 'when signed in as someone else' do
    let(:stranger) { create(:member) }

    before { sign_in stranger }

    it 'shows the bed but offers no way to change it' do
      lettuce.update!(bed_x: 0, bed_y: 0)
      visit_layout

      expect(page).to have_css('.garden-layout-planting', text: 'lettuce')
      expect(page).to have_no_button 'Resize bed'
      expect(page).to have_no_css('.garden-layout-planting[draggable="true"]')
    end
  end
end
