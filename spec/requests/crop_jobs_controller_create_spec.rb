# frozen_string_literal: true

require 'rails_helper'

describe CropJobsController, '#create' do
  let(:crop) { create(:tomato) }
  let(:template) { create(:crop_job_template, crop:, status: 'published') }

  before { create(:crop_job_step, crop_job_template: template, name: 'Stake the plants') }

  context 'when signed out' do
    before { post crop_jobs_path(crop) }

    it { expect(response).to redirect_to(new_member_session_path) }
    it { expect(Job.count).to eq 0 }
  end

  context 'when signed in' do
    let(:member) { create(:member) }

    before do
      sign_in member
      post crop_jobs_path(crop)
    end

    it { expect(response).to redirect_to(crop_path(crop)) }
    it { expect(member.jobs.pluck(:name)).to eq ['Stake the plants'] }
    it { expect(flash[:notice]).to eq 'Added 1 tomato job to your jobs.' }

    context 'when posted again' do
      before { post crop_jobs_path(crop) }

      it { expect(member.jobs.count).to eq 1 }
      it { expect(flash[:notice]).to eq 'Your jobs already have the tomato growing jobs.' }
    end
  end

  context 'when signed in and choosing a planting' do
    let(:member) { create(:member) }
    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }
    let!(:latest) { create(:planting, crop:, owner: member, planted_at: Time.zone.today) }
    let!(:of_variety) { create(:planting, crop: variety, owner: member, planted_at: 1.day.ago) }

    before { sign_in member }

    it 'adds the jobs to the planting of a variety' do
      post crop_jobs_path(crop), params: { planting_id: of_variety.id }
      expect(member.jobs.map(&:jobbable).uniq).to eq [of_variety]
    end

    it 'does not use somebody else\'s planting' do
      post crop_jobs_path(crop), params: { planting_id: create(:planting, crop:, planted_at: Time.zone.today).id }
      expect(response).to have_http_status(:not_found)
    end

    it 'does not make jobs for somebody else\'s planting' do
      post crop_jobs_path(crop), params: { planting_id: create(:planting, crop:, planted_at: Time.zone.today).id }
      expect(Job.count).to eq 0
    end
  end
end
