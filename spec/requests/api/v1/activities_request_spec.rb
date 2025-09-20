# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities', type: :request do
  subject { response.parsed_body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:activity) { FactoryBot.create(:activity, garden: create(:garden), planting: create(:planting)) }
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
end
