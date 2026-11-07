# frozen_string_literal: true

require 'rails_helper'

describe 'gardens/_archived_jobs' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }

  before do
    assign(:garden, garden)
  end

  context 'when there are no jobs' do
    it 'renders the empty message' do
      render partial: 'gardens/archived_jobs', locals: { jobs: [], total: 0 }

      expect(rendered).to have_css('h2', text: I18n.t('gardens.archived_jobs.title'))
      expect(rendered).to have_css('p', text: I18n.t('gardens.archived_jobs.empty'))
    end
  end

  context 'when there are jobs' do
    let(:planting) { create(:planting, owner:, garden:) }
    let(:finished_job) do
      create(:job, name: 'Water tomatoes', finished: true, finished_at: Time.zone.local(2026, 5, 1), owner:, garden:, planting:)
    end

    it 'renders job title, done badge, planting link, and owner attribution' do
      render partial: 'gardens/archived_jobs', locals: { jobs: [finished_job], total: 1 }

      expect(rendered).to have_css('h2', text: I18n.t('gardens.archived_jobs.title'))
      expect(rendered).to have_css('.badge', text: I18n.t('gardens.archived_jobs.done'))
      expect(rendered).to have_link(planting.to_s, href: planting_path(planting))
      expect(rendered).to include(I18n.t('gardens.archived_jobs.by', owner: owner.login_name))
    end

    it 'renders view all jobs link when total is greater than jobs shown' do
      render partial: 'gardens/archived_jobs', locals: { jobs: [finished_job], total: 5 }

      expect(rendered).to have_link(I18n.t('gardens.archived_jobs.view_all_jobs', total: 5))
    end
  end
end
