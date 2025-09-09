# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gardens', type: :request do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:garden) { FactoryBot.create(:garden) }
  let(:garden_encoded_as_json_api) do
    { "id"            => garden.id.to_s,
      "type"          => "gardens",
      "links"         => { "self" => resource_url },
      "attributes"    => { "name" => garden.name },
      "relationships" =>
                         {
                           "owner"     => owner_as_json_api,
                           "plantings" => plantings_as_json_api,
                           "photos"    => photos_as_json_api
                         } }
  end
  let(:resource_url) { "http://www.example.com/api/v1/gardens/#{garden.id}" }

  let(:plantings_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/plantings",
                   "related" => "#{resource_url}/plantings" } }
  end

  let(:owner_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/owner",
                   "related" => "#{resource_url}/owner" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/photos",
                   "related" => "#{resource_url}/photos" } }
  end

  it '#index' do
    get('/api/v1/gardens', params: {}, headers:)
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  it '#show' do
    get("/api/v1/gardens/#{garden.id}", params: {}, headers:)
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  context 'filtering' do
    let!(:garden2) { FactoryBot.create(:garden, active: false, garden_type: FactoryBot.create(:garden_type)) }
    pending 'filters by active' do
      get('/api/v1/gardens?filter[active]=true', params: {}, headers:)

        expect(response.status).to eq 200 
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(garden.id.to_s)
    end

    it 'filters by garden_type' do
      get("/api/v1/gardens?filter[garden_type]=#{garden2.garden_type.id}", params: {}, headers:)
      
      expect(response.status).to eq 200 
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(garden2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/gardens?filter[owner_id]=#{garden2.owner.id}", params: {}, headers:)

      expect(response.status).to eq 200 
      expect(subject['data'].size).to eq(2)
      expect(subject['data'][1]['id']).to eq(garden2.id.to_s)
    end
  end

  describe '#create' do
    let(:member) { create(:member) }
    let(:token) { member.regenerate_api_token; member.api_token.token }
    let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
    let(:auth_headers) { headers.merge('Authorization' => "Token token=#{token}") }
    let(:garden_params) do
      {
        data: {
          type: 'gardens',
          attributes: {
            name: 'My API Garden'
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      post '/api/v1/gardens', params: garden_params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      post '/api/v1/gardens', params: garden_params, headers: auth_headers
      expect(response).to have_http_status(:created)
      expect(member.gardens.count).to eq(2) # 1 from after_create callback, 1 from api
    end
  end
end
