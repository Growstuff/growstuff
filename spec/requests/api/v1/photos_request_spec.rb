# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photos' do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:photo)  { create(:photo) }
  let(:photo_encoded_as_json_api) do
    { "id"            => photo.id.to_s,
      "type"          => "photos",
      "attributes"    => attributes,
      "relationships" => {
        "owner"     => owner_as_json_api,
        "plantings" => plantings_as_json_api,
        "harvests"  => harvests_as_json_api,
        "gardens"   => gardens_as_json_api,
        "seeds"     => seeds_as_json_api
      } }
  end

  let(:owner_as_json_api) { related_link("members/#{photo.owner_id}") }

  let(:harvests_as_json_api) { related_link("harvests?filter[photo_id]=#{photo.id}") }

  let(:gardens_as_json_api) { related_link("gardens?filter[photo_id]=#{photo.id}") }

  let(:plantings_as_json_api) { related_link("plantings?filter[photo_id]=#{photo.id}") }

  let(:seeds_as_json_api) { related_link("seeds?filter[photo_id]=#{photo.id}") }

  let(:attributes) do
    {
      "thumbnail-url" => photo.thumbnail_url,
      "fullsize-url"  => photo.fullsize_url,
      "link-url"      => photo.link_url,
      "license-name"  => photo.license_name,
      "title"         => photo.title,
      "label"         => nil
    }
  end

  describe '#index' do
    before { get '/api/v1/photos', params: {}, headers: }

    it { expect(subject['data']).to include(photo_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/photos/#{photo.id}", params: {}, headers: }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("plantings" => plantings_as_json_api) }
    it { expect(subject['data']['relationships']).to include("harvests" => harvests_as_json_api) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']).to eq(photo_encoded_as_json_api) }
  end

  describe 'a photo of a seed packet' do
    let(:seed) { create(:seed) }
    let(:back) { create(:photo, owner: seed.owner) }
    let(:data) { subject['data'] }

    before { seed.photo_associations.create!(photo: back, label: 'back') }

    it 'says which side it is' do
      get "/api/v1/photos/#{back.id}", headers: headers
      expect(data['attributes']['label']).to eq 'back'
    end

    it 'says which seed it is of, when asked' do
      get "/api/v1/photos/#{back.id}", params: { include: 'seeds' }, headers: headers
      expect(data['relationships']['seeds']['data']).to eq [{ 'type' => 'seeds', 'id' => seed.id.to_s }]
    end
  end

  describe 'filtering by needs_ocr' do
    let(:seed) { create(:seed) }
    let(:read_seed) { create(:seed, packet_text: 'Sow by: December 2026') }
    let!(:needing) { create(:photo, owner: seed.owner).tap { |photo| seed.photo_associations.create!(photo:, label: 'back') } }
    let(:ids) { subject['data'].pluck('id') }

    before do
      read_seed.photo_associations.create!(photo: create(:photo, owner: read_seed.owner), label: 'back')
      seed.photo_associations.create!(photo: create(:photo, owner: seed.owner))
      get '/api/v1/photos', params: { filter: { needs_ocr: 'true' } }, headers:
    end

    it('finds the packet photo whose seed has no text') { expect(ids).to eq [needing.id.to_s] }
  end

  it '#create' do
    expect do
      post '/api/v1/photos', params: { 'photo' => { 'name' => 'can i make this' } }, headers:
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/photos/#{photo.id}", params: { 'photo' => { 'name' => 'can i modify this' } }, headers:
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/photos/#{photo.id}", params: {}, headers:
    end.to raise_error ActionController::RoutingError
  end
end
