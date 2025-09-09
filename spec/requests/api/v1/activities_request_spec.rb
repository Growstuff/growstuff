# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities', type: :request do
  subject { JSON.parse response.body }

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
      get("/api/v1/activities?filter[owner_id]=#{activity.owner.id}", params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by garden' do
        get("/api/v1/activities?filter[garden]=#{activity.garden.id}", params: {}, headers:)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by planting' do
        get("/api/v1/activities?filter[planting]=#{activity.planting.id}", params: {}, headers:)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end

    it 'filters by category' do
        get("/api/v1/activities?filter[category]=#{activity.category}", params: {}, headers:)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(activity.id.to_s)
    end
  end
end
