# frozen_string_literal: true

require 'rails_helper'

describe 'The garden layout', :js do
  include_context 'signed in member'

  let!(:garden)  { create(:garden, owner: member, name: 'Orchard', grid_columns: 4, grid_rows: 3) }
  let(:crop)     { create(:crop, name: 'lettuce') }
  let!(:lettuce) { create(:planting, garden:, owner: member, crop:, quantity: 2) }

  # Opening the layout would do this; done up front so examples can place plants first.
  before { garden.prepare_layout }

  def visit_layout
    visit layout_member_garden_path(member, garden)
  end

  def bed
    find('.garden-layout-cells')
  end

  def chip(name)
    find('.garden-layout-chip', text: name)
  end

  # The page saves after the screen has changed, so wait for the database too.
  def wait_until(timeout = Capybara.default_max_wait_time)
    Timeout.timeout(timeout) { sleep 0.1 until yield }
  end

  it 'draws the bed a cell per square, with the plantings as chips beside it' do
    visit_layout

    expect(page).to have_css('.garden-layout-cell', count: 12)
    expect(chip('lettuce')).to have_css('.garden-layout-chip-count', text: '2')
    expect(page).to have_no_css('.garden-layout-plant')
  end

  # Capybara drops at the middle of what it's dropped on: here, the whole bed.
  it 'puts a plant on the bed where a chip is dropped' do
    visit_layout
    chip('lettuce').drag_to(bed)

    expect(page).to have_css('.garden-layout-plant', count: 1)
    expect(chip('lettuce')).to have_css('.garden-layout-chip-count', text: '1')
    wait_until { lettuce.plants.placed.any? }
    # To within a pixel or so of the middle.
    placed = lettuce.plants.placed.first
    expect([placed.bed_x, placed.bed_y]).to match [be_within(0.05).of(2.0), be_within(0.05).of(1.5)]
  end

  it 'makes another plant when a chip is dragged out once they are all on the bed' do
    lettuce.plants.each_with_index { |plant, i| plant.update!(bed_x: i + 0.5, bed_y: 0.5) }
    visit_layout
    chip('lettuce').drag_to(bed)

    expect(page).to have_css('.garden-layout-plant', count: 3)
    wait_until { lettuce.reload.quantity == 3 }
  end

  it 'lifts a plant back off the bed when it is dropped on the sidebar' do
    lettuce.plants.first.update!(bed_x: 1.5, bed_y: 1.5)
    visit_layout
    find('.garden-layout-plant').drag_to(find('.garden-layout-tray-heading'))

    expect(page).to have_no_css('.garden-layout-plant')
    wait_until { lettuce.plants.placed.none? }
    expect(lettuce.reload.plants.count).to eq 2
  end

  describe 'the compost bin' do
    it 'sits under "About this garden"' do
      visit_layout

      expect(page).to have_css('#garden-layout-compost .garden-layout-compost', text: 'Compost bin')
    end

    it 'takes a plant dropped in it, and the planting has one fewer' do
      lettuce.plants.first.update!(bed_x: 1.5, bed_y: 1.5)
      visit_layout
      find('.garden-layout-plant').drag_to(find('.garden-layout-compost'))

      expect(page).to have_content 'Composted a lettuce.'
      wait_until { lettuce.reload.plants.one? }
      expect(lettuce.quantity).to eq 1
    end

    it 'takes one of the plants not yet on the bed when a chip is dropped in it' do
      visit_layout
      chip('lettuce').drag_to(find('.garden-layout-compost'))

      expect(chip('lettuce')).to have_css('.garden-layout-chip-count', text: '1')
      wait_until { lettuce.reload.plants.one? }
    end

    it 'refuses a chip whose plants are all on the bed' do
      lettuce.plants.each_with_index { |plant, i| plant.update!(bed_x: i + 0.5, bed_y: 0.5) }
      visit_layout
      chip('lettuce').drag_to(find('.garden-layout-compost'))

      expect(page).to have_content 'Every lettuce is on the bed.'
      expect(lettuce.reload.plants.count).to eq 2
    end
  end

  it 'resizes a plant by its handle' do
    plant = lettuce.plants.first.tap { |p| p.update!(bed_x: 2, bed_y: 1.5) }
    visit_layout
    circle = find('.garden-layout-plant')
    handle = circle.find('.garden-layout-resize', visible: :all)
    page.driver.browser.action.move_to(circle.native).perform
    page.driver.browser.action.move_to(handle.native).click_and_hold.move_by(40, 40).release.perform

    wait_until { plant.reload.diameter.to_f > 1 }
  end

  describe 'the size of the bed' do
    it 'changes as it is typed, and is saved' do
      visit_layout
      fill_in 'Columns', with: '6'

      expect(page).to have_css('.garden-layout-cell', count: 18)
      wait_until { garden.reload.grid_columns == 6 }
    end

    it 'refuses to shrink past a plant, and says why' do
      lettuce.plants.first.update!(bed_x: 3.5, bed_y: 1)
      visit_layout
      fill_in 'Columns', with: '2'

      expect(page).to have_content 'there are things out to column 4'
      expect(page).to have_css('.garden-layout-cell', count: 12)
      expect(garden.reload.grid_columns).to eq 4
    end
  end

  it 'clears the bed with Clear bed, keeping the plants' do
    lettuce.plants.each_with_index { |plant, i| plant.update!(bed_x: i + 0.5, bed_y: 0.5) }
    visit_layout
    accept_confirm { click_button 'Clear bed' }

    expect(page).to have_no_css('.garden-layout-plant')
    wait_until { lettuce.plants.placed.none? }
    expect(lettuce.reload.plants.count).to eq 2
  end

  it 'opens the planting dialog from Add a planting' do
    visit_layout
    click_button 'Add a planting'

    within('[role=dialog]') { expect(page).to have_content 'Plant something in Orchard' }
  end

  context 'when signed in as someone else' do
    let(:stranger) { create(:member) }

    before { sign_in stranger }

    it 'shows the bed but offers no way to change it' do
      lettuce.plants.first.update!(bed_x: 1.5, bed_y: 1.5)
      visit_layout

      expect(page).to have_css('.garden-layout-plant')
      expect(page).to have_no_css('[draggable="true"]')
      expect(page).to have_no_field 'Columns'
      expect(page).to have_no_button 'Add a planting'
      expect(page).to have_no_css('.garden-layout-compost')
    end
  end
end
