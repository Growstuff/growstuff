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
end
