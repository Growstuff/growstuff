# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Crops', type: :request do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:crop)   { FactoryBot.create :crop                    }
  let(:crop_encoded_as_json_api) do
    { "id"            => crop.id.to_s,
      "type"          => "crops",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "plantings" => plantings_as_json_api,
        "parent"    => parent_as_json_api,
        "harvests"  => harvests_as_json_api,
        "seeds"     => seeds_as_json_api,
        "photos"    => photos_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/crops/#{crop.id}" }

  let(:seeds_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/seeds",
                   "related" => "#{resource_url}/seeds" } }
  end

  let(:harvests_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/harvests",
                   "related" => "#{resource_url}/harvests" } }
  end

  let(:parent_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/parent",
                   "related" => "#{resource_url}/parent" } }
  end

  let(:plantings_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/plantings",
                   "related" => "#{resource_url}/plantings" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/photos",
                   "related" => "#{resource_url}/photos" } }
  end

  let(:attributes) do
    {
      "name"                         => crop.name,
      "en-wikipedia-url"             => crop.en_wikipedia_url,
      "perennial"                    => false,
      "median-lifespan"              => nil,
      "median-days-to-first-harvest" => nil,
      "median-days-to-last-harvest"  => nil
    }
  end

  describe '#index' do
    before { get '/api/v1/crops', params: {}, headers: headers }

    it { expect(subject['data']).to include(crop_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/crops/#{crop.id}", params: {}, headers: headers }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("plantings" => plantings_as_json_api) }
    it { expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api) }
    it { expect(subject['data']['relationships']).to include("seeds" => seeds_as_json_api) }
    it { expect(subject['data']['relationships']).to include("photos" => photos_as_json_api) }
    it { expect(subject['data']['relationships']).to include("parent" => parent_as_json_api) }
    it { expect(subject['data']).to eq(crop_encoded_as_json_api) }
  end

  it '#create' do
    expect do
      post '/api/v1/crops', params: { 'crop' => { 'name' => 'can i make this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/crops/#{crop.id}", params: { 'crop' => { 'name' => 'can i modify this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/crops/#{crop.id}", params: {}, headers: headers
    end.to raise_error ActionController::RoutingError
  end
end
