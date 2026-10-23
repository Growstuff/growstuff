# frozen_string_literal: true

require 'rails_helper'

describe 'Own jobs notepad' do
  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member, name: 'Berries garden') }

  before { login_as member }

  context 'with jobs' do
    before do
      create(:job, owner: member, name: 'Net the berries', garden:, due_date: Time.zone.today + 20.days)
      create(:job, owner: member, name: 'Dream of a greenhouse', due_date: nil)
      create(:job, owner: member, name: 'Pull the beans', finished: true)
      create(:job, name: 'Somebody else job')
      visit member_jobs_path(member)
    end

    it 'lists a job with its garden' do
      expect(page).to have_css('.notepad-job', text: /Net the berries.*Berries garden/m)
    end

    it 'groups jobs without a day under Some day' do
      expect(page).to have_css('.notepad-heading', text: 'Some day')
    end

    it 'keeps finished jobs in the list, ticked' do
      expect(page).to have_css('.notepad-job.done', text: 'Pull the beans')
    end

    it "leaves out other members' jobs" do
      expect(page).to have_no_content('Somebody else job')
    end

    it 'keeps a job in the list when it is crossed off' do
      click_button 'Cross off: Net the berries'
      expect(page).to have_css('.notepad-job.done', text: 'Net the berries')
    end

    it 'puts a job back on the list' do
      click_button 'Put back on the list: Pull the beans'
      expect(page).to have_css('.notepad-job:not(.done)', text: 'Pull the beans')
    end
  end

  context 'with the page loaded' do
    before { visit member_jobs_path(member) }

    it 'does not disable the Add button when the form is submitted' do
      expect(page).to have_css('input.notepad-add-button:not([data-disable-with])')
    end
  end

  context 'with several jobs due on the same day' do
    let(:names) { page.all('.notepad-name').map(&:text) }

    before do
      %w(First Second Third).each_with_index do |name, i|
        create(:job, owner: member, name:, due_date: Time.zone.today, created_at: (3 - i).minutes.ago)
      end
      visit member_jobs_path(member)
      click_button 'Cross off: First'
    end

    it 'keeps them in the same order when one is crossed off' do
      expect(names).to eq %w(First Second Third)
    end
  end

  context 'with a job crossed off this week' do
    before do
      create(:job, owner: member, finished: true)
      visit member_jobs_path(member)
    end

    it 'tells how many jobs are done this week' do
      expect(page).to have_css('.notepad-snail-caption', text: 'Slow and steady. 1 job done this week.', visible: :all)
    end
  end

  context 'when adding a job' do
    before do
      visit member_jobs_path(member)
      fill_in 'Add a job', with: 'Sow the peas'
      click_button 'Add'
    end

    it 'adds it to the list' do
      expect(page).to have_css('.notepad-job', text: 'Sow the peas')
    end

    it 'is the member\'s job' do
      expect(member.jobs.pluck(:name)).to eq ['Sow the peas']
    end
  end

  context 'without jobs' do
    before { visit member_jobs_path(member) }

    it 'has just the snail\'s encouragement' do
      expect(page).to have_css('.notepad-snail-caption', text: /\ASlow and steady\.\z/, visible: :all)
    end

    it 'still has places to put jobs' do
      expect(page).to have_css('.notepad-group', count: 3)
    end

    it 'says where to drag a job' do
      expect(page).to have_content('Drag a job here.', count: 3)
    end
  end

  context "when looking at another member's jobs" do
    let(:other) { create(:member) }

    before do
      create(:job, owner: other, name: 'Their weeding')
      visit member_jobs_path(other)
    end

    it 'lists them as cards, not a notepad' do
      expect(page).to have_css('.card.job', text: 'Their weeding')
    end
  end
end
