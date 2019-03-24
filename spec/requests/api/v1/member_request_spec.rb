# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Members', type: :request do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:member) { FactoryBot.create :member                  }
  let(:member_encoded_as_json_api) do
    { "id"            => member.id.to_s,
      "type"          => "members",
      "links"         => { "self" => resource_url },
      "attributes"    => attributes,
      "relationships" => {
        "gardens"   => gardens_as_json_api,
        "harvests"  => harvests_as_json_api,
        "photos"    => photos_as_json_api,
        "plantings" => plantings_as_json_api,
        "seeds"     => seeds_as_json_api
      } }
  end

  let(:resource_url) { "http://www.example.com/api/v1/members/#{member.id}" }

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

  let(:seeds_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/seeds",
                   "related" => "#{resource_url}/seeds" } }
  end

  let(:plantings_as_json_api) do
    { "links" =>
                 { "self"    =>
                                "#{resource_url}/relationships/plantings",
                   "related" => "#{resource_url}/plantings" } }
  end
  let(:gardens_as_json_api) do
    { "links" =>
                 { "self"    => "#{resource_url}/relationships/gardens",
                   "related" => "#{resource_url}/gardens" } }
  end

  let(:attributes) do
    {
      "login-name" => member.login_name,
      "slug"       => member.slug
    }
  end

  describe '#index' do
    before { get '/api/v1/members', params: {}, headers: headers }

    it { expect(subject['data']).to include(member_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/members/#{member.id}", params: {}, headers: headers }

    it { expect(subject['data']['relationships']).to include("gardens" => gardens_as_json_api) }
    it { expect(subject['data']['relationships']).to include("plantings" => plantings_as_json_api) }
    it { expect(subject['data']['relationships']).to include("seeds" => seeds_as_json_api) }
    it { expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api) }
    it { expect(subject['data']['relationships']).to include("photos" => photos_as_json_api) }
    it { expect(subject['data']).to eq(member_encoded_as_json_api) }
  end

  it '#create' do
    expect do
      post '/api/v1/members', params: { 'member' => { 'login_name' => 'can i make this' } }, headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/members/#{member.id}", params:  {
        'member' => { 'login_name' => 'can i modify this' }
      },
                                           headers: headers
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/members/#{member.id}", params: {}, headers: headers
    end.to raise_error ActionController::RoutingError
  end
end
