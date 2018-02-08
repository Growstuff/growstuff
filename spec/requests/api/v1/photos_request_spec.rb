require 'rails_helper'

RSpec.describe 'Photos', type: :request do
  subject { JSON.parse response.body }
  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:photo) { FactoryBot.create :photo }
  let(:photo_encoded_as_json_api) do
    { "id" => photo.id.to_s,
      "type" => "photos",
      "links" => { "self" => resource_url },
      "attributes" => attributes,
      "relationships" => {
        "owner" => owner_as_json_api,
        "plantings" => plantings_as_json_api,
        "harvests" => harvests_as_json_api,
        "gardens" => gardens_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/photos/#{photo.id}" }

  let(:owner_as_json_api) do
    { "links" =>
         { "self" => "#{resource_url}/relationships/owner",
           "related" => "#{resource_url}/owner" } }
  end

  let(:harvests_as_json_api) do
    { "links" =>
         { "self" => "#{resource_url}/relationships/harvests",
           "related" => "#{resource_url}/harvests" } }
  end

  let(:gardens_as_json_api) do
    { "links" =>
         { "self" => "#{resource_url}/relationships/gardens",
           "related" => "#{resource_url}/gardens" } }
  end

  let(:plantings_as_json_api) do
    { "links" =>
             { "self" =>
               "#{resource_url}/relationships/plantings",
               "related" => "#{resource_url}/plantings" } }
  end

  let(:attributes) do
    {
      "thumbnail-url" => photo.thumbnail_url,
      "fullsize-url" => photo.fullsize_url,
      "link-url" => photo.link_url,
      "license-name" => photo.license_name,
      "title" => photo.title
    }
  end

  describe '#index' do
    before { get '/api/v1/photos', {}, headers }
    it { expect(subject['data']).to include(photo_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/photos/#{photo.id}", {}, headers }
    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("plantings" => plantings_as_json_api) }
    it { expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']).to eq(photo_encoded_as_json_api) }
  end

  describe '#create' do
    before { post '/api/v1/photos', { 'photo' => { 'name' => 'can i make this' } }, headers }
    it { expect(response.code).to eq "404" }
  end

  describe '#update' do
    before { post "/api/v1/photos/#{photo.id}", { 'photo' => { 'name' => 'can i modify this' } }, headers }
    it { expect(response.code).to eq "404" }
  end

  describe '#delete' do
    before { delete "/api/v1/photos/#{photo.id}", {}, headers }
    it { expect(response.code).to eq "404" }
  end
end
