# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gardens' do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:garden) { create(:garden) }
  let(:garden_encoded_as_json_api) do
    { "id"            => garden.id.to_s,
      "type"          => "gardens",
      "attributes"    => { "name" => garden.name },
      "relationships" =>
                         {
                           "owner"     => owner_as_json_api,
                           "plantings" => plantings_as_json_api,
                           "photos"    => photos_as_json_api
                         } }
  end
  let(:plantings_as_json_api) { related_link("plantings?filter[garden_id]=#{garden.id}") }

  let(:owner_as_json_api) { related_link("members/#{garden.owner_id}") }

  let(:photos_as_json_api) { related_link("photos?filter[garden_id]=#{garden.id}") }

  it '#index' do
    get('/api/v1/gardens', params: {}, headers:)
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  it '#show' do
    get("/api/v1/gardens/#{garden.id}", params: {}, headers:)
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  context 'filtering' do
    let!(:garden2) { create(:garden, active: false, garden_type: create(:garden_type)) }

    it 'filters by active' do
      get('/api/v1/gardens?filter[active]=true', params: {}, headers:)

      expect(subject['data'].pluck('id')).not_to include(garden2.id.to_s)
    end

    it 'filters by garden_type' do
      get("/api/v1/gardens?filter[garden_type]=#{garden2.garden_type.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(garden2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/gardens?filter[owner_id]=#{garden2.owner.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(2)
      expect(subject['data'][1]['id']).to eq(garden2.id.to_s)
    end
  end

  it_behaves_like 'a resource members can write', 'gardens' do
    let(:create_params) { { attributes: { name: 'My API garden' } } }
    let(:own_record) { create(:garden, owner: member) }
    let(:other_record) { create(:garden) }
    let(:changes) { { name: 'An updated garden' } }
  end
end
