# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plantings', type: :request do
  subject { JSON.parse response.body }

  let(:headers)   { { 'Accept' => 'application/vnd.api+json' } }
  let!(:planting) { FactoryBot.create :planting }
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
    get '/api/v1/plantings', params: {}, headers: headers
    expect(subject['data'][0].keys).to eq(planting_encoded_as_json_api.keys)
    expect(subject['data'][0]['attributes'].keys.sort!).to eq(planting_encoded_as_json_api['attributes'].keys.sort!)
    expect(subject['data']).to include(planting_encoded_as_json_api)
  end

  it '#show' do
    get "/api/v1/plantings/#{planting.id}", params: {}, headers: headers
    expect(subject['data']['relationships']).to include("garden" => garden_as_json_api)
    expect(subject['data']['relationships']).to include("crop" => crop_as_json_api)
    expect(subject['data']['relationships']).to include("owner" => owner_as_json_api)
    expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api)
    expect(subject['data']['relationships']).to include("photos" => photos_as_json_api)
    expect(subject['data']).to eq(planting_encoded_as_json_api)
  end

  it '#create' do
    expect do
      post '/api/v1/plantings', params: { 'planting' => { 'description' => 'can i make this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/plantings/#{planting.id}", headers: headers, params: {
        'planting' => { 'description' => 'can i modify this' }
      }
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/plantings/#{planting.id}", params: {}, headers: headers
    end.to raise_error ActionController::RoutingError
  end
end
