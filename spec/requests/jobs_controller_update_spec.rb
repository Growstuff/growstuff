# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#update' do
  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member, due_date: nil) }
  let(:headers) { { 'X-Requested-With' => 'XMLHttpRequest' } }

  before { sign_in member }

  context 'when ordering jobs within a day' do
    let(:day) { Time.zone.today }
    let(:first_job) { create(:job, owner: member, due_date: day) }
    let(:last_job) { create(:job, owner: member, due_date: day) }

    before do
      first_job
      last_job
      patch job_path(job), params: { job: { due_date: day }, before_id: last_job.id }, headers:
    end

    it 'persists the chosen place between jobs' do
      expect(Job.where(id: [first_job.id, job.id, last_job.id]).order(:position).pluck(:id))
        .to eq [first_job.id, job.id, last_job.id]
    end

    it 'returns the saved order in the notepad' do
      expect(Capybara.string(response.body).all('.notepad-group-today .notepad-job').map { |row| row['data-id'].to_i })
        .to eq [first_job.id, job.id, last_job.id]
    end

    it 'keeps the order on a fresh page load' do
      get member_jobs_path(member)
      expect(Capybara.string(response.body).all('.notepad-group-today .notepad-job').map { |row| row['data-id'].to_i })
        .to eq [first_job.id, job.id, last_job.id]
    end
  end

  context 'when dropping a job at the end of an undated list' do
    let(:other) { create(:job, owner: member, due_date: nil) }

    it 'places it after existing jobs' do
      other
      patch job_path(job), params: { job: { due_date: '' }, before_id: '' }, headers: headers
      expect(Job.where(id: [job.id, other.id]).order(:position).pluck(:id)).to eq [other.id, job.id]
    end
  end

  context 'when the drop refers to another member’s private job' do
    let(:other) { create(:job, due_date: Time.zone.today) }

    it 'rejects the move' do
      patch job_path(job), params: { job: { due_date: other.due_date }, before_id: other.id }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not change the original date' do
      patch job_path(job), params: { job: { due_date: other.due_date }, before_id: other.id }, headers: headers
      expect(job.reload.due_date).to be_nil
    end
  end

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
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'crossing off an overdue job' do
    let(:job) { create(:job, owner: member, name: 'Late one', due_date: 3.days.ago.to_date) }

    context 'with the page keeping it where it is' do
      before { patch job_path(job), params: { job: { finished: '1' }, keep: [job.id] }, headers: }

      it 'leaves it in Overdue' do
        expect(Capybara.string(response.body)).to have_css('.notepad-group-overdue', text: 'Late one')
      end
    end

    context 'with a page that has not kept it' do
      before { patch job_path(job), params: { job: { finished: '1' } }, headers: }

      it 'moves it to Done' do
        expect(Capybara.string(response.body)).to have_css('.notepad-group-done', text: 'Late one')
      end
    end
  end
end
