# frozen_string_literal: true

require 'rails_helper'

describe GardensController, '#show' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }
  let(:page) { Capybara.string(response.body) }

  before do
    create(:job, owner:, garden:, name: 'Net the berries')
    create(:job, owner:, name: 'Sharpen the secateurs')
    create(:job, garden:, name: 'Someone else\'s job')
  end

  context 'when the garden\'s owner is signed in' do
    before do
      sign_in owner
      get garden_path(garden)
    end

    it 'has a to-do list for the garden' do
      expect(page).to have_css('.notepad h2', text: "Jobs in #{garden.name}")
    end

    it 'lists their jobs for the garden' do
      expect(page).to have_css('.notepad-name', text: 'Net the berries')
    end

    it 'leaves out their jobs for other gardens' do
      expect(page).to have_no_css('.notepad-name', text: 'Sharpen the secateurs')
    end

    it 'leaves out other members\' jobs' do
      expect(page).to have_no_css('.notepad-name', text: 'Someone else\'s job')
    end

    it 'links to all their jobs' do
      expect(page).to have_link('See all your jobs', href: member_jobs_path(owner))
    end

    it 'adds new jobs to the garden' do
      expect(page).to have_css(".notepad-add input[name='job[garden_id]'][value='#{garden.id}']", visible: :all)
    end

    it 'does not take over the page by focusing the add box' do
      expect(page).to have_no_css('.notepad-add input[autofocus]')
    end

    it 'does not show a garden chip on each job, as they are all for the garden' do
      expect(page).to have_no_css('.notepad-chip.garden')
    end
  end

  context 'when someone else is looking' do
    before do
      sign_in create(:member)
      get garden_path(garden)
    end

    it 'shows the jobs planned there, as cards' do
      expect(page).to have_css('.card.job', text: 'Net the berries')
    end

    it 'has no to-do list' do
      expect(page).to have_no_css('.notepad')
    end
  end

  context 'when nobody is signed in' do
    before { get garden_path(garden) }

    it 'has no to-do list' do
      expect(page).to have_no_css('.notepad')
    end
  end
end
