# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gardens', type: :request do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:garden) { FactoryBot.create :garden                  }
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
    get '/api/v1/gardens', params: {}, headers: headers
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  it '#show' do
    get "/api/v1/gardens/#{garden.id}", params: {}, headers: headers
    expect(subject['data']).to include(garden_encoded_as_json_api)
  end

  it '#create' do
    expect do
      post '/api/v1/gardens', params: { 'garden' => { 'name' => 'can i make this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/gardens/#{garden.id}", params: { 'garden' => { 'name' => 'can i modify this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/gardens/#{garden.id}", params: {}, headers: headers
    end.to raise_error ActionController::RoutingError
  end
end
