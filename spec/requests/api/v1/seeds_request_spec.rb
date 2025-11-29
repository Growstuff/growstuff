# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Seeds', type: :request do
  include_context 'with authenticated member'
  subject { JSON.parse response.body }

  let!(:seed)   { FactoryBot.create(:seed, owner: member) }
  let(:seed_encoded_as_json_api) do
    { "id"            => seed.id.to_s,
      "type"          => "seeds",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "owner" => owner_as_json_api,
        "crop"  => crop_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/seeds/#{seed.id}" }

  let(:owner_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/owner",
                   "related" => "#{resource_url}/owner" } }
  end

  let(:crop_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/crop",
                   "related" => "#{resource_url}/crop" } }
  end

  let(:attributes) do
    {
      "description"             => seed.description,
      "quantity"                => seed.quantity,
      "plant-before"            => seed.plant_before.strftime('%Y-%m-%d'),
      "tradable-to"             => seed.tradable_to,
      "days-until-maturity-min" => seed.days_until_maturity_min,
      "days-until-maturity-max" => seed.days_until_maturity_max,
      "organic"                 => seed.organic,
      "gmo"                     => seed.gmo,
      "heirloom"                => seed.heirloom
    }
  end

  describe '#index' do
    before { get '/api/v1/seeds', params: {}, headers: headers }

    it { expect(subject['data']).to include(seed_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/seeds/#{seed.id}", params: {}, headers: headers }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']['relationships']).to include("crop" => crop_as_json_api) }
    it { expect(subject['data']).to eq(seed_encoded_as_json_api) }
  end

  describe '#create' do
    let(:crop) { create(:crop) }
    let(:seed_params) do
      {
        data: {
          type:          'seeds',
          attributes:    {
            description: 'My API seeds'
          },
          relationships: {
            crop: { data: { type: 'crops', id: crop.id } }
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      post '/api/v1/seeds', params: seed_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      expect do
        post '/api/v1/seeds', params: seed_params, headers: headers
      end.to change { member.seeds.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    let(:other_member_seed) { create(:seed) }
    let(:update_params) do
      {
        data: {
          type:       'seeds',
          id:         seed.id.to_s,
          attributes: {
            description: 'An updated seed'
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      patch "/api/v1/seeds/#{seed.id}", params: update_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 200 OK with a valid token for own seed' do
      patch "/api/v1/seeds/#{seed.id}", params: update_params, headers: headers
      expect(response).to have_http_status(:ok)
      expect(seed.reload.description).to eq('An updated seed')
    end

    it 'returns 403 Forbidden for another member\'s seed' do
      update_params_for_other = {
        data: {
          type:       'seeds',
          id:         other_member_seed.id.to_s,
          attributes: {
            description: 'An updated seed'
          }
        }
      }.to_json
      patch "/api/v1/seeds/#{other_member_seed.id}", params: update_params_for_other, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe '#delete' do
    let(:other_member_seed) { create(:seed) }

    it 'returns 401 Unauthorized without a token' do
      delete "/api/v1/seeds/#{seed.id}", headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 204 No Content with a valid token for own seed' do
      delete "/api/v1/seeds/#{seed.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Seed.find_by(id: seed.id)).to be_nil
    end

    it 'returns 403 Forbidden for another member\'s seed' do
      delete "/api/v1/seeds/#{other_member_seed.id}", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'filtering' do
    let!(:seed2) do
      FactoryBot.create(:seed, owner: member, tradable_to: 'nationally', organic: 'certified organic', gmo: 'certified GMO-free', heirloom: 'heirloom')
    end
    let!(:other_member_seed) { create(:seed) }

    it 'filters by crop' do
      get("/api/v1/seeds?filter[crop]=#{seed2.crop.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by tradable_to' do
      get('/api/v1/seeds?filter[tradable_to]=nationally', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by organic' do
      get('/api/v1/seeds?filter[organic]=certified organic', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by gmo' do
      get('/api/v1/seeds?filter[gmo]=certified GMO-free', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by heirloom' do
      get('/api/v1/seeds?filter[heirloom]=heirloom', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/seeds?filter[owner_id]=#{member.id}", params: {}, headers: headers)
      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'].map { |s| s['id'] }).to include(seed.id.to_s, seed2.id.to_s)

      get("/api/v1/seeds?filter[owner_id]=#{other_member_seed.owner.id}", params: {}, headers: headers)
      expect(response).to have_http_status(:ok)
      expect(subject['data']).to be_empty
    end
  end
end
