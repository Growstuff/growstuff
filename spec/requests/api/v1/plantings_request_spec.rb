# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plantings', type: :request do
  subject { response.parsed_body }

  let(:headers)   { { 'Accept' => 'application/vnd.api+json' } }
  let!(:planting) { create(:planting) }
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
      "planted-at"          => "2014-07-30",
      "failed"              => false,
      "finished-at"         => nil,
      "finished"            => false,
      "quantity"            => 33,
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
    get('/api/v1/plantings', params: {}, headers:)
    expect(subject['data'][0].keys).to eq(planting_encoded_as_json_api.keys)
    expect(subject['data'][0]['attributes'].keys.sort!).to eq(planting_encoded_as_json_api['attributes'].keys.sort!)
    expect(subject['data']).to include(planting_encoded_as_json_api)
  end

  it '#show' do
    get("/api/v1/plantings/#{planting.id}", params: {}, headers:)
    expect(subject['data']['relationships']).to include("garden" => garden_as_json_api)
    expect(subject['data']['relationships']).to include("crop" => crop_as_json_api)
    expect(subject['data']['relationships']).to include("owner" => owner_as_json_api)
    expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api)
    expect(subject['data']['relationships']).to include("photos" => photos_as_json_api)
    expect(subject['data']).to eq(planting_encoded_as_json_api)
  end

  describe '#create' do
    let!(:member) { create(:member) }
    let(:token) do
      member.regenerate_api_token
      member.api_token.token
    end
    let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }
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
      post '/api/v1/plantings', params: planting_params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      post '/api/v1/plantings', params: planting_params, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(member.plantings.count).to eq(1)
    end
  end

  describe '#update' do
    let!(:member) { create(:member) }
    let(:token) do
      member.regenerate_api_token
      member.api_token.token
    end
    let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }
    let(:planting) { create(:planting, owner: member) }
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
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 200 OK with a valid token for own planting' do
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: auth_headers

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
      patch "/api/v1/plantings/#{other_member_planting.id}", params: update_params_for_other, headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe '#delete' do
    let!(:member) { create(:member) }
    let(:token) do
      member.regenerate_api_token
      member.api_token.token
    end
    let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }
    let!(:planting) { create(:planting, owner: member) }
    let(:other_member_planting) { create(:planting) }

    it 'returns 401 Unauthorized without a token' do
      delete "/api/v1/plantings/#{planting.id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 204 No Content with a valid token for own planting' do
      delete "/api/v1/plantings/#{planting.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)
      expect(Garden.find_by(id: planting.id)).to be_nil
    end

    it 'returns 403 Forbidden for another member\'s planting' do
      delete "/api/v1/plantings/#{other_member_planting.id}", headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "by member/owner" do
    before :each do
      @member1 = planting.owner
      @planting2 = create(:planting, owner: create(:owner))
      @member2 = @planting2.owner
    end

    describe "#show" do
      it "locates the correct member" do
        get "/api/v1/plantings?filter[owner-id]=#{@member1.id}"
        expect(response.parsed_body['data'][0]['id']).to eq(planting.id.to_s)

        get "/api/v1/plantings?filter[owner-id]=#{@member2.id}"
        expect(response.parsed_body['data'][0]['id']).to eq(@planting2.id.to_s)

        pending "The below should be identical to the above, but aren't."

        get "/api/v1/members/#{@member1.id}/plantings"
        expect(response.parsed_body['data'][0]['id']).to eq(planting.id.to_s)

        get "/api/v1/members/#{@member2.id}/plantings"
        expect(response.parsed_body['data'][0]['id']).to eq(@planting2.id.to_s)
      end
    end
  end

  context 'filtering' do
    let!(:planting2) { create(:planting, failed: true, sunniness: 'shade') }
    let!(:perennial_planting) { create(:planting, crop: create(:crop, perennial: true)) }

    it 'filters by failed' do
      get('/api/v1/plantings?filter[failed]=true', params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(planting2.id.to_s)
    end

    it 'filters by sunniness' do
      get('/api/v1/plantings?filter[sunniness]=shade', params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(planting2.id.to_s)
    end

    it 'filters by perennial' do
      get('/api/v1/plantings?filter[perennial]=true', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(perennial_planting.id.to_s)
    end

    it 'filters by active' do
      get('/api/v1/plantings?filter[active]=true', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'][0]['id']).to eq(planting.id.to_s)
    end
  end
end
