# frozen_string_literal: true

require 'rails_helper'

describe CropJobsController, '#create' do
  let(:crop) { create(:tomato) }
  let(:season) { 'any' }
  let(:template) { create(:crop_job_template, crop:, status: 'published', season:) }
  let(:member) { create_located_member('Wellington, Wellington Region, New Zealand', -41.29, 174.78) }

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

  context 'with a template for spring and summer, planting in a southern winter' do
    let(:season) { 'spring_summer' }

    before { sign_in member }

    context 'without having agreed' do
      before { post crop_jobs_path(crop), params: { planting_on: '2027-06-13' } }

      it { expect(Job.count).to eq 0 }
      it { expect(Capybara.string(response.body)).to have_css('.crop-job-season-warning', text: 'outside that where you are') }
      it { expect(Capybara.string(response.body)).to have_button('Add them anyway') }
    end

    context 'having agreed' do
      before { post crop_jobs_path(crop), params: { planting_on: '2027-06-13', confirm: '1' } }

      it { expect(Job.where(owner: member).count).to eq 1 }
    end

    context 'planting in spring' do
      before { post crop_jobs_path(crop), params: { planting_on: '2026-10-10' } }

      it { expect(Job.where(owner: member).count).to eq 1 }
    end
  end

  context 'with a template for spring and summer, for a member who has not said where they are' do
    let(:season) { 'spring_summer' }
    let(:member) { create(:member) }

    before do
      sign_in member
      post crop_jobs_path(crop), params: { planting_on: '2027-06-13' }
    end

    it { expect(Job.where(owner: member).count).to eq 1 }
  end
end
