# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#create' do
  let(:member) { create(:member) }
  # The notepad adds a job with an AJAX request.
  let(:headers) { { 'X-Requested-With' => 'XMLHttpRequest' } }

  before { sign_in member }

  context 'with a name' do
    before { post jobs_path, params: { job: { name: 'Sow the peas' } }, headers: }

    it 'creates the job' do
      expect(member.jobs.pluck(:name)).to eq ['Sow the peas']
    end

    it 'responds with created' do
      expect(response).to have_http_status(:created)
    end

    it 'sends back the groups with the new job in them' do
      expect(response.body).to include('Sow the peas')
    end
  end

  context 'without a name' do
    before { post jobs_path, params: { job: { name: '' } }, headers: }

    it 'rejects it' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'creates nothing' do
      expect(member.jobs.count).to eq 0
    end
  end
end
