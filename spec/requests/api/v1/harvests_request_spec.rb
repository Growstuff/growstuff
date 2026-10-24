# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Harvests' do
  subject { JSON.parse response.body }

  let(:headers)  { { 'Accept' => 'application/vnd.api+json' } }
  let!(:harvest) { create(:harvest) }
  let(:harvest_encoded_as_json_api) do
    { "id"            => harvest.id.to_s,
      "type"          => "harvests",
      "attributes"    => attributes,
      "relationships" => {
        "crop"     => crop_as_json_api,
        "planting" => planting_as_json_api,
        "owner"    => owner_as_json_api,
        "photos"   => photos_as_json_api
      } }
  end

  let(:crop_as_json_api) { related_link("crops/#{harvest.crop_id}") }

  let(:owner_as_json_api) { related_link("members/#{harvest.owner_id}") }

  let(:planting_as_json_api) { { 'links' => { 'related' => nil } } }

  let(:photos_as_json_api) { related_link("photos?filter[harvest_id]=#{harvest.id}") }

  let(:attributes) do
    {
      "harvested-at"    => "2015-09-17",
      "description"     => harvest.description,
      "unit"            => harvest.unit,
      "weight-quantity" => harvest.weight_quantity.to_s,
      "weight-unit"     => harvest.weight_unit,
      "si-weight"       => harvest.si_weight
    }
  end

  describe '#index' do
    before { get '/api/v1/harvests', params: {}, headers: }

    it { expect(subject['data']).to include(harvest_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/harvests/#{harvest.id}", params: {}, headers: }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("planting" => planting_as_json_api) }
    it { expect(subject['data']['relationships']).to include("crop" => crop_as_json_api) }
    it { expect(subject['data']['relationships']).to include("photos" => photos_as_json_api) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']).to eq(harvest_encoded_as_json_api) }
  end

  context 'filtering' do
    let!(:harvest2) { create(:harvest, planting: create(:planting)) }

    it 'filters by crop' do
      get("/api/v1/harvests?filter[crop_id]=#{harvest2.crop.id}", params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/harvests?filter[planting_id]=#{harvest2.planting.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by plant_part' do
      get("/api/v1/harvests?filter[plant_part]=#{harvest2.plant_part.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/harvests?filter[owner_id]=#{harvest2.owner.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end
  end

  it_behaves_like 'a resource members can write', 'harvests' do
    let(:planting) { create(:planting, owner: member, garden: create(:garden, owner: member)) }
    let(:create_params) do
      { attributes:    { description: 'My API harvest' },
        relationships: { planting: { data: { type: 'plantings', id: planting.id.to_s } } } }
    end
    let(:own_record) { create(:harvest, owner: member) }
    let(:other_record) { create(:harvest) }
    let(:changes) { { description: 'An updated harvest' } }

    before { create(:plant_part) }
  end
end
