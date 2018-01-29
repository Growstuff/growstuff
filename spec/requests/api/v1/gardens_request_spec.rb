require 'rails_helper'

RSpec.describe 'Gardens', type: :request do
  subject { JSON.parse response.body }
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:garden) { FactoryBot.create :garden }
  let(:garden_encoded_as_json_api) do
    { "id" => garden.id.to_s,
      "type" => "gardens",
      "links" => { "self" => resource_url },
      "attributes" => { "name" => garden.name },
      "relationships" =>
      {
        "owner" => owner_as_json_api,
        "plantings" => plantings_as_json_api,
        "photos" => photos_as_json_api
      } }
  end
  let(:resource_url) { "http://www.example.com/api/v1/gardens/#{garden.id}" }

  let(:plantings_as_json_api) do
    { "links" =>
      { "self" =>
        "#{resource_url}/relationships/plantings",
        "related" => "#{resource_url}/plantings" } }
  end

  let(:owner_as_json_api) do
    { "links" =>
         { "self" => "#{resource_url}/relationships/owner",
           "related" => "#{resource_url}/owner" } }
  end

  let(:photos_as_json_api) do
    { "links" =>
         { "self" => "#{resource_url}/relationships/photos",
           "related" => "#{resource_url}/photos" } }
  end

  scenario '#index' do
    get '/api/v1/gardens', {}, headers
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  scenario '#show' do
    get "/api/v1/gardens/#{garden.id}", {}, headers
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  scenario '#create' do
    post '/api/v1/gardens', { 'garden' => { 'name' => 'can i make this' } }, headers
    expect(response.code).to eq "404"
  end

  scenario '#update' do
    post "/api/v1/gardens/#{garden.id}", { 'garden' => { 'name' => 'can i modify this' } }, headers
    expect(response.code).to eq "404"
  end

  scenario '#delete' do
    delete "/api/v1/gardens/#{garden.id}", {}, headers
    expect(response.code).to eq "404"
  end
end
