# frozen_string_literal: true

require 'rails_helper'

describe JobIdeasController do
  include ActiveSupport::Testing::TimeHelpers

  let(:member) { create(:member) }
  let(:today) { Date.new(2026, 10, 23) }
  let(:crop) { create(:crop, name: 'garlic', perennial: false) }

  before do
    travel_to(today.in_time_zone.change(hour: 12))
    sign_in member
    create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.new(2025, 10, 28), jobbable: crop)
  end

  describe 'GET /job_ideas' do
    before { get job_ideas_path }

    it 'responds with ok' do
      expect(response).to have_http_status(:ok)
    end

    it 'suggests the job' do
      expect(response.body).to include('Snip off scapes')
    end

    it 'says why' do
      expect(response.body).to include('You did this on 28 Oct.')
    end
  end

  describe 'GET /job_ideas when signed out' do
    before do
      sign_out member
      get job_ideas_path
    end

    it 'sends them to sign in' do
      expect(response).to redirect_to(new_member_session_path)
    end
  end

  describe 'POST /job_ideas' do
    let(:key) { "past_job:snip off scapes:#{crop.id}" }

    before { post job_ideas_path, params: { key: } }

    it 'adds the job' do
      expect(member.jobs.active.pluck(:name)).to eq ['Snip off scapes']
    end

    it 'adds it about the crop' do
      expect(member.jobs.active.first.jobbable).to eq crop
    end

    it 'goes back to the ideas' do
      expect(response).to redirect_to(job_ideas_path)
    end

    context 'with an idea that is not on offer' do
      let(:key) { 'past_job:something else:' }

      it 'adds nothing' do
        expect(member.jobs.active).to be_empty
      end
    end

    context 'with a planting idea' do
      let(:key) { "past_planting:#{crop.id}" }

      before do
        create(:planting, owner: member, crop:, planted_at: Date.new(2025, 10, 28))
        post job_ideas_path, params: { key: }
      end

      it 'adds a job to plant the crop' do
        expect(member.jobs.action_plant.pluck(:name)).to eq ['Plant garlic']
      end

      it 'no longer suggests it' do
        expect(JobIdeas.new(member, today:).ideas.map(&:key)).not_to include(key)
      end
    end
  end

  describe 'POST /job_ideas/hide' do
    let(:key) { "past_job:snip off scapes:#{crop.id}" }
    let(:hidden) { member.job_idea_dismissals.hiding.find_by(key:) }

    it 'snoozes for a week' do
      post hide_job_ideas_path, params: { key:, length: 'week' }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.week.from_now)
    end

    it 'dismisses for a year without a length' do
      post hide_job_ideas_path, params: { key: }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.year.from_now)
    end

    it 'dismisses for a year with a length it does not offer' do
      post hide_job_ideas_path, params: { key:, length: 'decade' }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.year.from_now)
    end

    it 'stops suggesting it' do
      post hide_job_ideas_path, params: { key: }
      get job_ideas_path
      expect(response.body).not_to include('Snip off scapes')
    end
  end
end
