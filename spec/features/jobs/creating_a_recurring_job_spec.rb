# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a recurring job' do
  let(:member) { create(:member) }
  let!(:garden) { create(:garden, owner: member) }

  before do
    login_as(member)
    visit new_job_path
  end

  scenario 'a member creates a recurring job' do
    fill_in 'What needs to be done?', with: 'Water the plants'
    fill_in 'Repeat how many times?', with: '3'
    fill_in 'Every how many weeks?', with: '2'
    click_button 'Save'

    expect(page).to have_content('Job was successfully created.')
    expect(Job.count).to eq(4)

    original_job = Job.first
    expect(original_job.name).to eq('Water the plants')
    expect(original_job.due_date).to eq(Date.today)

    second_job = Job.second
    expect(second_job.name).to eq('Water the plants')
    expect(second_job.due_date).to eq(Date.today + 2.weeks)

    third_job = Job.third
    expect(third_job.name).to eq('Water the plants')
    expect(third_job.due_date).to eq(Date.today + 4.weeks)

    fourth_job = Job.fourth
    expect(fourth_job.name).to eq('Water the plants')
    expect(fourth_job.due_date).to eq(Date.today + 6.weeks)
  end
end
