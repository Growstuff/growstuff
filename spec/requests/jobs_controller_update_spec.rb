# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#update' do
  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member, due_date: nil) }
  let(:headers) { { 'X-Requested-With' => 'XMLHttpRequest' } }

  before { sign_in member }

  context 'when moving a job to a day from the notepad' do
    before { patch job_path(job), params: { job: { due_date: '2026-10-24' } }, headers: }

    it 'gives it the day' do
      expect(job.reload.due_date).to eq Date.new(2026, 10, 24)
    end

    it 'sends back the groups' do
      expect(response.body).to include(job.name)
    end
  end

  context 'when moving a job to no day' do
    let(:job) { create(:job, owner: member, due_date: Date.new(2026, 10, 24)) }

    before { patch job_path(job), params: { job: { due_date: '' } }, headers: }

    it 'clears the day' do
      expect(job.reload.due_date).to be_nil
    end
  end

  context 'when crossing a job off from the notepad' do
    before { patch job_path(job), params: { job: { finished: '1' } }, headers: }

    it 'finishes the job' do
      expect(job.reload).to be_finished
    end

    it 'says how many jobs are done this week' do
      expect(response.headers['X-Jobs-Done-This-Week']).to eq '1'
    end
  end

  context 'when renaming a job from the notepad' do
    before { patch job_path(job), params: { job: { name: 'Sow the beans' } }, headers: }

    it 'saves the new name' do
      expect(job.reload.name).to eq 'Sow the beans'
    end

    it 'sends back the groups with the new name' do
      expect(response.body).to include('Sow the beans')
    end
  end

  context 'when renaming a job to nothing' do
    before { patch job_path(job), params: { job: { name: '' } }, headers: }

    it 'keeps the name' do
      expect(job.reload.name).not_to be_blank
    end

    it 'says it failed' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
