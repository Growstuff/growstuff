# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities', type: :request do
  include_context 'with authenticated member'
  subject { JSON.parse response.body }

  let(:garden) { create(:garden, owner: member) }
  let(:planting) { create(:planting, garden: garden) }
  let!(:activity) { FactoryBot.create(:activity, garden: garden, planting: planting, owner: member) }
  let!(:activity2) { FactoryBot.create(:activity) }

  it '#index' do
    get('/api/v1/activities', params: {}, headers: headers)
    expect(subject['data'].size).to eq(1)
    expect(subject['data'][0]['id']).to eq(activity.id.to_s)
  end

  it '#show' do
    get("/api/v1/activities/#{activity.id}", params: {}, headers: headers)
    expect(subject['data']['id']).to eq(activity.id.to_s)
  end

  context 'filtering' do
    it 'filters by owner' do
      get("/api/v1/activities?filter[owner-id]=#{activity.owner.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by garden' do
      get("/api/v1/activities?filter[garden-id]=#{activity.garden.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/activities?filter[planting-id]=#{activity.planting.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by category' do
      activity2.update!(category: activity.category)
      get("/api/v1/activities?filter[category]=#{activity.category}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end
  end
end
