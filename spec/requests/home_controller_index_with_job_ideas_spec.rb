# frozen_string_literal: true

require 'rails_helper'

describe HomeController, '#index with job ideas' do
  let(:member) { create(:member) }
  let(:page) { Capybara.string(response.body) }

  before do
    Rails.cache.clear
    sign_in member
  end

  context 'when there are ideas to review' do
    before do
      create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.current - 1.year + 2.days)
      get root_path
    end

    it 'has a yellow bar saying so' do
      expect(page).to have_css('.home-ideas .notepad-ideas', text: 'We have 1 suggested job for you this week')
    end

    it 'leads to their jobs with the ideas showing' do
      expect(page).to have_link(href: member_jobs_path(member, ideas: 1), class: 'notepad-ideas')
    end

    it 'does not open the overlay, which is not on this page' do
      expect(page).to have_no_css('[data-job-ideas-open]')
    end
  end

  context 'when there are none' do
    before { get root_path }

    it 'has no yellow bar' do
      expect(page).to have_no_css('.notepad-ideas')
    end
  end

  context 'when signed out' do
    before do
      sign_out member
      get root_path
    end

    it 'has no yellow bar' do
      expect(page).to have_no_css('.notepad-ideas')
    end
  end
end
