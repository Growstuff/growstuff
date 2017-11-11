require 'rails_helper'

RSpec.describe 'Plantings', type: :request do
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:planting) { FactoryBot.create :planting }
  let(:planting_encoded_as_json_api) do
    { "id" => planting.id.to_s,
      "type" => "plantings",
      "links" => { "self" => "http://www.example.com/api/v1/plantings/#{planting.id}" },
      "attributes" => attributes,
      "relationships" => {
        "garden" => garden_as_json_api,
        "crop" => crop_as_json_api,
        "owner" => owner_as_json_api,
        "photos" => photos_as_json_api,
        "harvests" => harvests_as_json_api
      } }
  end

  let(:harvests_as_json_api) do
    { "links" =>
         { "self" => "http://www.example.com/api/v1/plantings/#{planting.id}/relationships/harvests",
           "related" => "http://www.example.com/api/v1/plantings/#{planting.id}/harvests" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
         { "self" => "http://www.example.com/api/v1/plantings/#{planting.id}/relationships/photos",
           "related" => "http://www.example.com/api/v1/plantings/#{planting.id}/photos" } }
  end

  let(:owner_as_json_api) do
    { "links" =>
         { "self" => "http://www.example.com/api/v1/plantings/#{planting.id}/relationships/owner",
           "related" => "http://www.example.com/api/v1/plantings/#{planting.id}/owner" } }
  end

  let(:crop_as_json_api) do
    { "links" =>
             { "self" =>
               "http://www.example.com/api/v1/plantings/#{planting.id}/relationships/crop",
               "related" => "http://www.example.com/api/v1/plantings/#{planting.id}/crop" } }
  end
  let(:garden_as_json_api) do
    { "links" =>
         { "self" => "http://www.example.com/api/v1/plantings/#{planting.id}/relationships/garden",
           "related" => "http://www.example.com/api/v1/plantings/#{planting.id}/garden" } }
  end

  let(:attributes) do
    {
      "planted-at" => "2014-07-30",
      "finished-at" => nil,
      "finished" => false,
      "quantity" => 33,
      "description" => planting.description,
      "sunniness" => nil,
      "planted-from" => nil,
      "expected-lifespan" => nil,
      "finish-predicted-at" => nil,
      "percentage-grown" => nil,
      "first-harvest-date" => nil,
      "last-harvest-date" => nil
    }
  end

  subject { JSON.parse response.body }
  scenario '#index' do
    get '/api/v1/plantings', {}, headers
    expect(subject['data']).to include(planting_encoded_as_json_api)
  end

  scenario '#show' do
    get "/api/v1/plantings/#{planting.id}", {}, headers
    expect(subject['data']['relationships']).to include("garden" => garden_as_json_api)
    expect(subject['data']['relationships']).to include("crop" => crop_as_json_api)
    expect(subject['data']['relationships']).to include("owner" => owner_as_json_api)
    expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api)
    expect(subject['data']).to eq(planting_encoded_as_json_api)
  end

  scenario '#create' do
    post '/api/v1/plantings', { 'planting' => { 'description' => 'can i make this' } }, headers
    expect(response.code).to eq "404"
  end

  scenario '#update' do
    post "/api/v1/plantings/#{planting.id}", { 'planting' => { 'description' => 'can i modify this' } }, headers
    expect(response.code).to eq "404"
  end

  scenario '#delete' do
    delete "/api/v1/plantings/#{planting.id}", {}, headers
    expect(response.code).to eq "404"
  end
end
