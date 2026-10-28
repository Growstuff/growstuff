# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Crops' do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:crop)   { create(:crop) }
  let(:crop_encoded_as_json_api) do
    { "id"            => crop.id.to_s,
      "type"          => "crops",
      "attributes"    => attributes,
      "relationships" => {
        "plantings" => plantings_as_json_api,
        "parent"    => parent_as_json_api,
        "harvests"  => harvests_as_json_api,
        "seeds"     => seeds_as_json_api,
        "photos"    => photos_as_json_api
      } }
  end

  let(:seeds_as_json_api) { related_link("seeds?filter[crop_id]=#{crop.id}") }

  let(:harvests_as_json_api) { related_link("harvests?filter[crop_id]=#{crop.id}") }

  let(:parent_as_json_api) { { 'links' => { 'related' => nil } } }

  let(:plantings_as_json_api) { related_link("plantings?filter[crop_id]=#{crop.id}") }

  let(:photos_as_json_api) { related_link("photos?filter[crop_id]=#{crop.id}") }

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
    before { get '/api/v1/crops', params: {}, headers: }

    it { expect(subject['data']).to include(crop_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/crops/#{crop.id}", params: {}, headers: }

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
      post '/api/v1/crops', params: { 'crop' => { 'name' => 'can i make this' } }, headers:
    end.to raise_error ActionController::RoutingError
  end

  it '#update' do
    expect do
      post "/api/v1/crops/#{crop.id}", params: { 'crop' => { 'name' => 'can i modify this' } }, headers:
    end.to raise_error ActionController::RoutingError
  end

  it '#delete' do
    expect do
      delete "/api/v1/crops/#{crop.id}", params: {}, headers:
    end.to raise_error ActionController::RoutingError
  end
end
