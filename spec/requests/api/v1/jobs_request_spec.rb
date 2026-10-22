# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Jobs' do
  subject { JSON.parse response.body }

  let(:member) { create(:member) }
  let(:token) do
    member.regenerate_api_token
    member.api_token.token
  end
  let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
  let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }
  let!(:job) { create(:job, owner: member, garden: create(:garden, owner: member), planting: create(:planting, owner: member)) }
  let!(:job2) { create(:job) }

  it '#index' do
    get('/api/v1/jobs', params: {}, headers:)
    expect(subject['data'].size).to eq(2)
  end

  it '#show' do
    get("/api/v1/jobs/#{job.id}", params: {}, headers:)
    expect(subject['data']['id']).to eq(job.id.to_s)
  end

  context 'filtering' do
    it 'filters by owner' do
      get("/api/v1/jobs?filter[owner-id]=#{job.owner.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(job.id.to_s)
    end

    it 'filters by garden' do
      get("/api/v1/jobs?filter[garden-id]=#{job.garden.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(job.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/jobs?filter[planting-id]=#{job.planting.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(job.id.to_s)
    end
  end

  describe '#update' do
    let(:params) do
      {
        'data' => {
          'type' => 'jobs',
          'id' => job.id.to_s,
          'attributes' => {
            'description' => 'A new description',
            'finished' => true,
            'due-date' => '2025-10-31'
          }
        }
      }
    end

    it 'updates the job' do
      patch "/api/v1/jobs/#{job.id}", params: params.to_json, headers: auth_headers

      expect(response).to have_http_status(:ok)

      # Check response
      expect(subject['data']['attributes']['description']).to eq('A new description')
      expect(subject['data']['attributes']['finished']).to eq(true)
      expect(subject['data']['attributes']['due-date']).to eq('2025-10-31')

      # Check database
      job.reload
      expect(job.description).to eq('A new description')
      expect(job.finished).to eq(true)
      expect(job.due_date.to_s).to eq('2025-10-31')
    end
  end
end
