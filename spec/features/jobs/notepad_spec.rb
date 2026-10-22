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

    it 'leaves out finished jobs' do
      expect(page).to have_no_content('Pull the beans')
    end

    it "leaves out other members' jobs" do
      expect(page).to have_no_content('Somebody else job')
    end

    it 'shows finished jobs under Done' do
      click_link 'Done'
      expect(page).to have_css('.notepad-job.done', text: 'Pull the beans')
    end
  end

  context 'without jobs' do
    before { visit member_jobs_path(member) }

    it 'invites the member to add one' do
      expect(page).to have_content('Add a job to start your list.')
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
