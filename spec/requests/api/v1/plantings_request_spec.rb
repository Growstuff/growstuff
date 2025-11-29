# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plantings', type: :request do
  include_context 'with authenticated member'
  subject { JSON.parse response.body }

  let!(:planting) { FactoryBot.create(:planting, owner: member) }
  let(:planting_encoded_as_json_api) do
    { "id"            => planting.id.to_s,
      "type"          => "plantings",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "garden"   => garden_as_json_api,
        "crop"     => crop_as_json_api,
        "owner"    => owner_as_json_api,
        "photos"   => photos_as_json_api,
        "harvests" => harvests_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/plantings/#{planting.id}" }

  let(:harvests_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/harvests",
                   "related" => "#{resource_url}/harvests" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/photos",
                   "related" => "#{resource_url}/photos" } }
  end

  let(:owner_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/owner",
                   "related" => "#{resource_url}/owner" } }
  end

  let(:crop_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/crop",
                   "related" => "#{resource_url}/crop" } }
  end
  let(:garden_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/garden",
                   "related" => "#{resource_url}/garden" } }
  end

  let(:attributes) do
    {
      "slug"                => planting.slug,
      "planted-at"          => planting.planted_at.strftime('%Y-%m-%d'),
      "failed"              => false,
      "finished-at"         => nil,
      "finished"            => false,
      "quantity"            => planting.quantity,
      "description"         => planting.description,
      "crop-name"           => planting.crop.name,
      "crop-slug"           => planting.crop.slug,
      "sunniness"           => nil,
      "planted-from"        => nil,
      "expected-lifespan"   => nil,
      "finish-predicted-at" => nil,
      "percentage-grown"    => nil,
      "first-harvest-date"  => nil,
      "last-harvest-date"   => nil,
      "thumbnail"           => nil,
      "location"            => planting.garden.location,
      "longitude"           => planting.garden.longitude,
      "latitude"            => planting.garden.latitude
    }
  end

  it '#index' do
    get('/api/v1/plantings', params: {}, headers: headers)
    expect(subject['data'][0].keys).to eq(planting_encoded_as_json_api.keys)
    expect(subject['data'][0]['attributes'].keys.sort!).to eq(planting_encoded_as_json_api['attributes'].keys.sort!)
    expect(subject['data']).to include(planting_encoded_as_json_api)
  end

  it '#show' do
    get("/api/v1/plantings/#{planting.id}", params: {}, headers: headers)
    expect(subject['data']['relationships']).to include("garden" => garden_as_json_api)
    expect(subject['data']['relationships']).to include("crop" => crop_as_json_api)
    expect(subject['data']['relationships']).to include("owner" => owner_as_json_api)
    expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api)
    expect(subject['data']['relationships']).to include("photos" => photos_as_json_api)
    expect(subject['data']).to eq(planting_encoded_as_json_api)
  end

  describe '#create' do
    let(:crop) { create(:crop) }
    let(:garden) { create(:garden, owner: member) }
    let(:planting_params) do
      {
        data: {
          type:          'plantings',
          attributes:    {
            description: 'My API plantings'
          },
          relationships: {
            crop:   { data: { type: 'crops', id: crop.id } },
            garden: { data: { type: 'gardens', id: garden.id } }
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      post '/api/v1/plantings', params: planting_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      expect do
        post '/api/v1/plantings', params: planting_params, headers: headers
      end.to change { member.plantings.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    let(:other_member_planting) { create(:planting) }
    let(:update_params) do
      {
        data: {
          type:       'plantings',
          id:         planting.id.to_s,
          attributes: {
            description: 'An updated planting'
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 200 OK with a valid token for own planting' do
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: headers

      expect(response).to have_http_status(:ok)
      expect(planting.reload.description).to eq('An updated planting')
    end

    it 'returns 403 Forbidden for another member\'s planting' do
      update_params_for_other = {
        data: {
          type:       'plantings',
          id:         other_member_planting.id.to_s,
          attributes: {
            description: 'An updated planting'
          }
        }
      }.to_json
      patch "/api/v1/plantings/#{other_member_planting.id}", params: update_params_for_other, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe '#delete' do
    let(:other_member_planting) { create(:planting) }

    it 'returns 401 Unauthorized without a token' do
      delete "/api/v1/plantings/#{planting.id}", headers: unauthenticated_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 204 No Content with a valid token for own planting' do
      garden = planting.garden
      delete "/api/v1/plantings/#{planting.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Planting.find_by(id: planting.id)).to be_nil
      expect(Garden.find_by(id: garden.id)).not_to be_nil
    end

    it 'returns 403 Forbidden for another member\'s planting' do
      delete "/api/v1/plantings/#{other_member_planting.id}", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "by member/owner" do
    let!(:planting2) { create(:planting, owner: create(:owner)) }
    let(:member2) { planting2.owner }

    describe "on /api/v1/plantings" do
      it "filters by owner but respects authorization scope" do
        # Filtering by the current member's id should work
        get "/api/v1/plantings?filter[owner-id]=#{member.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(planting.id.to_s)

        # Filtering by another member's id should return nothing from the scoped collection
        get "/api/v1/plantings?filter[owner-id]=#{member2.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(subject['data']).to be_empty
      end
    end

    describe "on /api/v1/members/:id/plantings" do
      it "returns plantings for the correct member" do
        get "/api/v1/members/#{member.id}/plantings", headers: headers
        expect(response).to have_http_status(:ok)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(planting.id.to_s)
      end

      it "returns forbidden when accessing another member's plantings" do
        get "/api/v1/members/#{member2.id}/plantings", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'filtering' do
    let!(:planting2) { FactoryBot.create(:planting, owner: member, failed: true, sunniness: 'shade') }
    let!(:perennial_planting) { FactoryBot.create(:planting, owner: member, crop: FactoryBot.create(:crop, perennial: true)) }

    it 'filters by failed' do
      get('/api/v1/plantings?filter[failed]=true', params: {}, headers: headers)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(planting2.id.to_s)
    end

    it 'filters by sunniness' do
      get('/api/v1/plantings?filter[sunniness]=shade', params: {}, headers: headers)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(planting2.id.to_s)
    end

    it 'filters by perennial' do
      get('/api/v1/plantings?filter[perennial]=true', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(perennial_planting.id.to_s)
    end

    it 'filters by active' do
      get('/api/v1/plantings?filter[active]=true', params: {}, headers: headers)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'].map { |p| p['id'] }).to include(planting.id.to_s, perennial_planting.id.to_s)
    end
  end
end
