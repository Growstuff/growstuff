# frozen_string_literal: true

require 'rails_helper'

describe 'Marking a planting finished from a garden card', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }
  let!(:kale) { create(:annual_crop, name: 'kale') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: lettuce, planted_at: 10.days.ago) }

  before { visit gardens_path }

  # The menu shows its items in lowercase (CSS), but links are found by their text.
  def open_dialog(crop = 'lettuce')
    within('.planting-row', text: crop) do
      click_link "Actions for #{crop}"
      click_link 'Mark as finished'
    end
  end

  # Sets a date the way a person's picking one does for React: the input's own
  # value setter, then an input event (Capybara's fill_in doesn't reach it).
  def set_date(date)
    page.execute_script(<<~JS, date.iso8601)
      const input = document.getElementById('mark-finished-date');
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(input, arguments[0]);
      input.dispatchEvent(new Event('input', { bubbles: true }));
    JS
  end

  it 'opens a dialog over the list asking when it finished, with today chosen' do
    open_dialog

    within '[role=dialog]' do
      expect(page).to have_content 'Mark lettuce as finished'
      expect(page).to have_content 'When did it finish?'
      expect(page).to have_checked_field 'Today', visible: :all
      expect(page).to have_css '.pill-choice', text: 'Enter date'
      expect(page).to have_no_button 'Cancel'
      expect(page).to have_no_field 'Date'
    end
    expect(page).to have_current_path(gardens_path)
    expect(planting.reload.finished).to be false
  end

  it 'finishes it today, and it leaves the list, without leaving the page' do
    open_dialog

    within('[role=dialog]') { click_button 'Mark as finished' }

    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_content 'Marked lettuce as finished.'
    expect(page).to have_no_css '.planting-row', text: 'lettuce'
    expect(page).to have_current_path(gardens_path)
    expect(planting.reload).to have_attributes(finished: true, finished_at: Time.zone.today)
  end

  it 'lets you enter the date it finished' do
    open_dialog

    within '[role=dialog]' do
      find('label', text: 'Enter date').click
      set_date(3.days.ago.to_date)
      click_button 'Mark as finished'
    end

    expect(page).to have_content 'Marked lettuce as finished.'
    expect(planting.reload).to have_attributes(finished: true, finished_at: 3.days.ago.to_date)
  end

  it 'says what is wrong, and keeps the dialog, when the date is not allowed' do
    open_dialog

    within '[role=dialog]' do
      find('label', text: 'Enter date').click
      # Before the planting: the browser's own limit is bypassed here to reach the server's rule.
      page.execute_script("document.getElementById('mark-finished-date').removeAttribute('min')")
      set_date(20.days.ago.to_date)
      click_button 'Mark as finished'

      expect(page).to have_content 'That didn’t save'
      expect(page).to have_content 'Finished at'
    end
    expect(planting.reload.finished).to be false
  end

  it 'does not offer today for a planting made today, and starts the dates the day after' do
    create(:planting, garden: garden, owner: member, crop: kale, planted_at: Time.zone.today)
    visit gardens_path
    open_dialog('kale')

    within '[role=dialog]' do
      expect(page).to have_no_css '.pill-choice', text: 'Today'
      expect(page).to have_field 'Date', with: (Time.zone.today + 1).iso8601
      expect(page).to have_css "#mark-finished-date[min='#{(Time.zone.today + 1).iso8601}']"
    end
  end
end
