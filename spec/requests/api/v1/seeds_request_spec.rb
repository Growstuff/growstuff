# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photos', type: :request do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:seed)   { FactoryBot.create :seed                    }
  let(:seed_encoded_as_json_api) do
    { "id"            => seed.id.to_s,
      "type"          => "seeds",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "owner" => owner_as_json_api,
        "crop"  => crop_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/seeds/#{seed.id}" }

  let(:owner_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/owner",
                   "related" => "#{resource_url}/owner" } }
  end

  let(:crop_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/crop",
                   "related" => "#{resource_url}/crop" } }
  end

  let(:attributes) do
    {
      "description"             => seed.description,
      "quantity"                => seed.quantity,
      "plant-before"            => "2013-07-15",
      "tradable-to"             => seed.tradable_to,
      "days-until-maturity-min" => seed.days_until_maturity_min,
      "days-until-maturity-max" => seed.days_until_maturity_max,
      "organic"                 => seed.organic,
      "gmo"                     => seed.gmo,
      "heirloom"                => seed.heirloom
    }
  end

  describe '#index' do
    before { get '/api/v1/seeds', params: {}, headers: headers }

    it { expect(subject['data']).to include(seed_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/seeds/#{seed.id}", params: {}, headers: headers }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']['relationships']).to include("crop" => crop_as_json_api) }
    it { expect(subject['data']).to eq(seed_encoded_as_json_api) }
  end

  it '#create' do
    expect do
      post '/api/v1/seeds', params: { 'seed' => { 'name' => 'can i make this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/seeds/#{seed.id}", params: { 'seed' => { 'name' => 'can i modify this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/seeds/#{seed.id}", params: {}, headers: headers
    end.to raise_error ActionController::RoutingError
  end
end
