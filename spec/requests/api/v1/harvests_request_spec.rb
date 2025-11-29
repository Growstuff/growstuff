# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Harvests', type: :request do
  include_context 'with authenticated member'
  subject { JSON.parse response.body }

  let!(:harvest) { FactoryBot.create(:harvest, owner: member) }
  let(:harvest_encoded_as_json_api) do
    { "id"            => harvest.id.to_s,
      "type"          => "harvests",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "crop"     => crop_as_json_api,
        "planting" => planting_as_json_api,
        "owner"    => owner_as_json_api,
        "photos"   => photos_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/harvests/#{harvest.id}" }

  let(:crop_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/crop",
                   "related" => "#{resource_url}/crop" } }
  end

  let(:owner_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/owner",
                   "related" => "#{resource_url}/owner" } }
  end

  let(:planting_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/planting",
                   "related" => "#{resource_url}/planting" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/photos",
                   "related" => "#{resource_url}/photos" } }
  end

  let(:attributes) do
    {
      "harvested-at"    => harvest.harvested_at.strftime('%Y-%m-%d'),
      "description"     => harvest.description,
      "unit"            => harvest.unit,
      "weight-quantity" => harvest.weight_quantity.to_s,
      "weight-unit"     => harvest.weight_unit,
      "si-weight"       => harvest.si_weight
    }
  end

  describe '#index' do
    before { get '/api/v1/harvests', params: {}, headers: headers }

    it { expect(subject['data']).to include(harvest_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/harvests/#{harvest.id}", params: {}, headers: headers }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("planting" => planting_as_json_api) }
    it { expect(subject['data']['relationships']).to include("crop" => crop_as_json_api) }
    it { expect(subject['data']['relationships']).to include("photos" => photos_as_json_api) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']).to eq(harvest_encoded_as_json_api) }
  end

  context 'filtering' do
    let(:garden) { create(:garden, owner: member) }
    let(:planting) { create(:planting, garden: garden) }
    let!(:harvest2) { FactoryBot.create(:harvest, planting: planting) }

    it 'filters by crop' do
      get("/api/v1/harvests?filter[crop_id]=#{harvest2.crop.id}", params: {}, headers: headers)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/harvests?filter[planting_id]=#{harvest2.planting.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by plant_part' do
      get("/api/v1/harvests?filter[plant_part]=#{harvest2.plant_part.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/harvests?filter[owner_id]=#{harvest2.owner.id}", params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'].map { |h| h['id'] }).to include(harvest.id.to_s, harvest2.id.to_s)
    end
  end

  describe '#create' do
    let(:planting) { create(:planting, owner: member) }
    let(:harvest_params) do
      {
        data: {
          type:          'harvests',
          attributes:    {
            description: 'My API harvests'
          },
          relationships: {
            planting: { data: { type: 'plantings', id: planting.id } }
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      post '/api/v1/harvests', params: harvest_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      expect do
        post '/api/v1/harvests', params: harvest_params, headers: headers
      end.to change { member.harvests.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    let(:other_member_harvest) { create(:harvest) }
    let(:update_params) do
      {
        data: {
          type:       'harvests',
          id:         harvest.id.to_s,
          attributes: {
            description: 'An updated harvest'
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      patch "/api/v1/harvests/#{harvest.id}", params: update_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 200 OK with a valid token for own harvest' do
      patch "/api/v1/harvests/#{harvest.id}", params: update_params, headers: headers

      expect(response).to have_http_status(:ok)
      expect(harvest.reload.description).to eq('An updated harvest')
    end

    it 'returns 403 Forbidden for another member\'s harvest' do
      update_params_for_other = {
        data: {
          type:       'harvests',
          id:         other_member_harvest.id.to_s,
          attributes: {
            description: 'An updated harvest'
          }
        }
      }.to_json
      patch "/api/v1/harvests/#{other_member_harvest.id}", params: update_params_for_other, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe '#delete' do
    let(:other_member_harvest) { create(:harvest) }

    it 'returns 401 Unauthorized without a token' do
      delete "/api/v1/harvests/#{harvest.id}", headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 204 No Content with a valid token for own harvest' do
      garden = harvest.planting.garden
      delete "/api/v1/harvests/#{harvest.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Harvest.find_by(id: harvest.id)).to be_nil
      expect(Garden.find_by(id: garden.id)).not_to be_nil
    end

    it 'returns 403 Forbidden for another member\'s harvest' do
      delete "/api/v1/harvests/#{other_member_harvest.id}", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
