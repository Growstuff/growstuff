# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a recurring activity' do
  let(:member) { create(:member) }
  let!(:garden) { create(:garden, owner: member) }

  before do
    login_as(member)
    visit new_activity_path
  end

  scenario 'a member creates a recurring activity' do
    fill_in 'What needs to be done?', with: 'Water the plants'
    select 'Watering', from: 'activity_category'
    fill_in 'Repeat how many times?', with: '3'
    fill_in 'Every how many weeks?', with: '2'
    click_button 'Save'

    expect(page).to have_content('Activity was successfully created.')
    expect(Activity.count).to eq(4)

    original_activity = Activity.first
    expect(original_activity.name).to eq('Water the plants')
    expect(original_activity.due_date).to eq(Date.today)

    second_activity = Activity.second
    expect(second_activity.name).to eq('Water the plants')
    expect(second_activity.due_date).to eq(Date.today + 2.weeks)

    third_activity = Activity.third
    expect(third_activity.name).to eq('Water the plants')
    expect(third_activity.due_date).to eq(Date.today + 4.weeks)

    fourth_activity = Activity.fourth
    expect(fourth_activity.name).to eq('Water the plants')
    expect(fourth_activity.due_date).to eq(Date.today + 6.weeks)
  end
end
