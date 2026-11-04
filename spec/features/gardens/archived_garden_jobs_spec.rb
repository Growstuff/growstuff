# frozen_string_literal: true

require 'rails_helper'

describe 'Jobs on an archived garden' do
  let(:owner) { create(:member) }
  let(:garden) { create(:inactive_garden, owner:) }

  before do
    create(:job, owner:, garden:, name: 'Water the beans', finished: true)
    11.times { |i| create(:job, owner:, garden:, name: "Chore #{i}") }
    login_as owner
  end

  context 'with the garden page' do
    before { visit garden_path(garden) }

    it 'lists only the first ten jobs' do
      expect(page).to have_css('.archived-jobs li', count: 10)
    end

    it 'offers to view all the jobs' do
      expect(page).to have_link 'View all 12 jobs'
    end

    it 'has no notepad to edit' do
      expect(page).to have_no_css('.notepad')
    end
  end

  context 'when viewing all jobs' do
    before { visit garden_path(garden, all_jobs: 1) }

    it 'lists every job' do
      expect(page).to have_css('.archived-jobs li', count: 12)
    end

    it 'shows which were done' do
      expect(page).to have_css('.archived-jobs li', text: 'Water the beans Done')
    end
  end
end
