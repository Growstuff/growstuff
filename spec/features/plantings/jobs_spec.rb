# frozen_string_literal: true

require 'rails_helper'

describe 'Jobs on a planting' do
  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:planting) { create(:planting, owner: member, garden:) }

  before { login_as member }

  context 'with a planned and a finished job' do
    let!(:planned) { create(:job, owner: member, planting:, garden:, name: 'Net the berries') }

    before do
      create(:job, owner: member, planting:, garden:, name: 'Pull the beans', finished: true)
      visit planting_path(planting)
    end

    it 'lists the planned job as not done' do
      expect(page).to have_css('.job-checklist-item:not(.done)', text: 'Net the berries')
    end

    it 'lists the finished job as done' do
      expect(page).to have_css('.job-checklist-item.done', text: 'Pull the beans')
    end

    it 'goes back to the planting when a job is ticked' do
      click_button 'Cross off: Net the berries'
      expect(page).to have_current_path(planting_path(planting))
    end

    it 'finishes the job when it is ticked' do
      click_button 'Cross off: Net the berries'
      expect(planned.reload.finished).to be true
    end

    it 'puts a job back on the list when it is unticked' do
      click_button 'Put back on the list: Pull the beans'
      expect(page).to have_css('.job-checklist-item:not(.done)', text: 'Pull the beans')
    end
  end

  context 'when ticking a job', :js do
    let!(:planned) { create(:job, owner: member, planting:, garden:, name: 'Net the berries') }

    before do
      visit planting_path(planting)
      page.execute_script('window.sameDocument = true')
      click_button 'Cross off: Net the berries'
    end

    it 'shows the job as done' do
      expect(page).to have_css('.job-checklist-item.done', text: 'Net the berries')
    end

    it 'does not reload the page' do
      expect(page).to have_css('.job-checklist-item.done')
      expect(page.evaluate_script('window.sameDocument')).to be true
    end
  end

  context 'when adding a job in the dialog', :js do
    let(:due_date) { Date.new(2031, 3, 14) }

    before do
      visit planting_path(planting)
      within('#jobs') { click_link 'add' }
      within('#planting-job-modal') do
        fill_in 'job_name', with: 'Stake the tomatoes'
        fill_in 'job_due_date', with: due_date.strftime('%d%m%Y')
        click_button 'Add job'
      end
    end

    it 'shows the job on the planting page' do
      expect(page).to have_css('.job-checklist-item', text: 'Stake the tomatoes')
    end

    it 'saves the day it is due' do
      expect(page).to have_css('.job-checklist-item', text: 'Stake the tomatoes')
      expect(Job.find_by(name: 'Stake the tomatoes').due_date).to eq due_date
    end

    it 'links the job to the planting' do
      expect(page).to have_css('.job-checklist-item', text: 'Stake the tomatoes')
      expect(Job.find_by(name: 'Stake the tomatoes').planting).to eq planting
    end
  end

  context 'when looking at someone else\'s planting' do
    before do
      create(:job, owner: planting.owner, planting:, garden:, name: 'Net the berries')
      login_as create(:member)
      visit planting_path(planting)
    end

    it 'shows no tick button' do
      expect(page).to have_no_button('Cross off: Net the berries')
    end

    it 'shows no add dialog' do
      expect(page).to have_no_css('#planting-job-modal')
    end
  end
end
