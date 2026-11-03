# frozen_string_literal: true

require 'rails_helper'

describe CropJobsController, '#create' do
  let(:crop) { create(:tomato) }
  let(:template) { create(:crop_job_template, crop:, status: 'published') }
  let(:member) { create(:member) }

  before { create(:crop_job_step, crop_job_template: template, name: 'Stake the plants', offset_amount: 2) }

  context 'when signed out' do
    before { post crop_jobs_path(crop) }

    it { expect(response).to redirect_to(new_member_session_path) }
    it { expect(Job.count).to eq 0 }
  end

  context 'when signed in and planting on a day' do
    before do
      sign_in member
      post crop_jobs_path(crop), params: { planting_on: '2027-03-01' }
    end

    it { expect(response).to redirect_to(crop_path(crop)) }
    it { expect(Job.where(owner: member).pluck(:due_date)).to eq [Date.new(2027, 3, 15)] }
    it { expect(flash[:notice]).to eq 'Added 1 tomato job to your jobs.' }

    context 'when posted again' do
      before { post crop_jobs_path(crop), params: { planting_on: '2027-03-01' } }

      it { expect(Job.where(owner: member).count).to eq 1 }
      it { expect(flash[:notice]).to eq 'Your jobs already have the tomato growing jobs.' }
    end
  end

  context 'when signed in with a day that is not a date' do
    before do
      sign_in member
      post crop_jobs_path(crop), params: { planting_on: 'someday' }
    end

    it { expect(Job.where(owner: member).pluck(:due_date)).to eq [AddCropJobs.default_planting_on + 2.weeks] }
  end

  context 'when choosing a planting' do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }
    let!(:of_variety) { create(:planting, crop: variety, owner: member, planted_at: 1.day.ago) }

    before { sign_in member }

    it 'adds the jobs to the planting of a variety' do
      post crop_jobs_path(crop), params: { planting_id: of_variety.id }
      expect(Job.where(owner: member).map(&:jobbable).uniq).to eq [of_variety]
    end

    it 'is not found for somebody else\'s planting' do
      post crop_jobs_path(crop), params: { planting_id: create(:planting, crop:, planted_at: 1.day.ago).id }
      expect(response).to have_http_status(:not_found)
    end

    it 'makes no jobs for somebody else\'s planting' do
      post crop_jobs_path(crop), params: { planting_id: create(:planting, crop:, planted_at: 1.day.ago).id }
      expect(Job.count).to eq 0
    end
  end
end
