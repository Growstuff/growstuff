# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#index with ideas' do
  let(:member) { create(:member) }
  let(:page) { Capybara.string(response.body) }

  before do
    Rails.cache.clear
    sign_in member
  end

  context 'when there are ideas' do
    before do
      create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.current - 1.year + 2.days)
      get member_jobs_path(member)
    end

    it 'says so in a yellow box over the jobs' do
      expect(page).to have_css('.notepad-ideas', text: 'We have 1 suggested job for you this week')
    end

    it 'has the overlay the links open' do
      expect(page).to have_css('#job-ideas-modal #job-ideas-body', visible: :all)
    end

    it 'links the box to the ideas' do
      expect(page).to have_link(href: '/job_ideas', class: 'notepad-ideas')
    end
  end

  context 'when there are none' do
    before { get member_jobs_path(member) }

    it 'has no box of links beside the jobs' do
      expect(page).to have_no_css('nav[aria-label="Jobs"]')
    end

    it 'shows no yellow box' do
      expect(page).to have_no_css('.notepad-ideas')
    end
  end
end
