require 'rails_helper'

RSpec.describe 'Gardens', type: :request do
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:garden) { FactoryBot.create :garden }
  let(:garden_encoded_as_json_api) do
    { "id" => garden.id.to_s,
      "type" => "gardens",
      "links" => { "self" => "http://www.example.com/api/v1/gardens/#{garden.id}" },
      "attributes" => { "name" => garden.name },
      "relationships" =>
     { "owner" =>
       { "links" =>
         { "self" => "http://www.example.com/api/v1/gardens/#{garden.id}/relationships/owner",
           "related" => "http://www.example.com/api/v1/gardens/#{garden.id}/owner" } },
       "plantings" =>
       { "links" =>
         { "self" =>
           "http://www.example.com/api/v1/gardens/#{garden.id}/relationships/plantings",
           "related" => "http://www.example.com/api/v1/gardens/#{garden.id}/plantings" } },
       "photos" =>
       { "links" =>
         { "self" => "http://www.example.com/api/v1/gardens/#{garden.id}/relationships/photos",
           "related" => "http://www.example.com/api/v1/gardens/#{garden.id}/photos" } } } }
  end

  subject { JSON.parse response.body }
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
