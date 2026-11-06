# frozen_string_literal: true

require 'rails_helper'

describe 'Adding a job as JSON' do
  let(:member) { FactoryBot.create(:member) }

  before { sign_in member }

  context 'with a name' do
    before { post jobs_path(format: :json), params: { job: { name: 'Build a trellis', due_date: '2026-11-01' } } }

    it { expect(response).to have_http_status(:created) }
    it { expect(Job.find_by(owner: member).due_date).to eq Date.new(2026, 11, 1) }
  end

  context 'without a name' do
    before { post jobs_path(format: :json), params: { job: { name: '' } } }

    it { expect(response).to have_http_status(:unprocessable_entity) }
    it { expect(response.parsed_body['errors']).to have_key('name') }
  end
end
