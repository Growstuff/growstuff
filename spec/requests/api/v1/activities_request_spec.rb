# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities', type: :request do
  subject { JSON.parse response.body }

  let(:member) { create(:member) }
  let(:token) do
      member.regenerate_api_token
      member.api_token.token
  end
  let(:authenticated_headers) do
    headers.merge { 'Authorization' => "Bearer #{token}" }
  end
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:activity) { FactoryBot.create(:activity, owner: member, garden: create(:garden, owner: member), planting: create(:planting, owner: member)) }
  let!(:activity2) { FactoryBot.create(:activity) }

  it '#index' do
    get('/api/v1/activities', params: {}, headers:)
    expect(subject['data'].size).to eq(2)
  end

  it '#show' do
    get("/api/v1/activities/#{activity.id}", params: {}, headers:)
    expect(subject['data']['id']).to eq(activity.id.to_s)
  end

  context 'filtering' do
    it 'filters by owner' do
      get("/api/v1/activities?filter[owner-id]=#{activity.owner.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by garden' do
      get("/api/v1/activities?filter[garden-id]=#{activity.garden.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/activities?filter[planting-id]=#{activity.planting.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by category' do
      get("/api/v1/activities?filter[category]=#{activity.category}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
      expect(subject['data'][1]['id']).to eq(activity2.id.to_s)
    end
  end

  context '#update' do
    let(:params) do
      {
        'data' => {
          'type' => 'activities',
          'id' => activity.id.to_s,
          'attributes' => {
            'description' => 'A new description',
            'finished' => true,
            'due-date' => '2025-10-31'
          }
        }
      }
    end

    it 'updates the activity' do
      patch "/api/v1/activities/#{activity.id}", params: params.to_json, headers: authenticated_headers

      puts response.body unless response.status.code == 200
      expect(response).to have_http_status(:ok)

      # Check response
      expect(subject['data']['attributes']['description']).to eq('A new description')
      expect(subject['data']['attributes']['finished']).to eq(true)
      expect(subject['data']['attributes']['due-date']).to eq('2025-10-31')

      # Check database
      activity.reload
      expect(activity.description).to eq('A new description')
      expect(activity.finished).to eq(true)
      expect(activity.due_date.to_s).to eq('2025-10-31')
    end
  end
end
