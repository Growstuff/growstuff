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

    it 'shows how many beside the link to them' do
      expect(page).to have_css('a[href="/job_ideas"] .badge', text: '1')
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

    it 'shows the link without a count' do
      expect(page).to have_link(href: '/job_ideas')
    end

    it 'shows no yellow box' do
      expect(page).to have_no_css('.notepad-ideas')
    end

    it 'shows no count' do
      expect(page).to have_no_css('a[href="/job_ideas"] .badge')
    end
  end
end
