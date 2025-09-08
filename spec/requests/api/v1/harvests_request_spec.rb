# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Harvests', type: :request do
  subject { JSON.parse response.body }

  let(:headers)  { { 'Accept' => 'application/vnd.api+json' } }
  let!(:harvest) { FactoryBot.create(:harvest) }
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
    let!(:harvest2) { FactoryBot.create(:harvest) }
    it 'filters by crop' do
      get("/api/v1/harvests?filter[crop]=#{harvest2.crop.id}", params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by planting' do
      get("/api/v1/harvests?filter[planting]=#{harvest2.planting.id}", params: {}, headers:)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end

    it 'filters by plant_part' do
        get("/api/v1/harvests?filter[plant_part]=#{harvest2.plant_part.id}", params: {}, headers:)
        expect(subject['data'].size).to eq(1)
        expect(subject['data'][0]['id']).to eq(harvest2.id.to_s)
    end
  end

  it '#create' do
    expect do
      put '/api/v1/harvests', headers:, params: {
        'harvest' => { 'description' => 'can i make this' }
      }
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/harvests/#{harvest.id}", headers:, params: {
        'harvest' => { 'description' => 'can i modify this' }
      }
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/harvests/#{harvest.id}", headers:, params: {}
    end.to raise_error ActionController::RoutingError
  end
end
