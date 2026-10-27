# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_reschedule' do
  let(:job) { build_stubbed(:job) }

  context 'when today is Wednesday' do
    let(:wednesday) { Date.new(2026, 10, 21) }

    before do
      travel_to(wednesday)
      render partial: 'jobs/reschedule', locals: { job: }
    end

    it 'has This week menu item' do
      expect(rendered).to have_link('This week', href: job_path(job, job: { due_date: '2026-10-23' }))
    end

    it 'has This weekend menu item' do
      expect(rendered).to have_link('This weekend', href: job_path(job, job: { due_date: '2026-10-24' }))
    end
  end

  context 'when today is Thursday' do
    let(:thursday) { Date.new(2026, 10, 22) }

    before do
      travel_to(thursday)
      render partial: 'jobs/reschedule', locals: { job: }
    end

    it 'has no This week menu item as Friday is tomorrow' do
      expect(rendered).to have_no_link('This week')
    end

    it 'has This weekend menu item' do
      expect(rendered).to have_link('This weekend', href: job_path(job, job: { due_date: '2026-10-24' }))
    end
  end
end
