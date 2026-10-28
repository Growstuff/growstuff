# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Seeds' do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:seed)   { create(:seed) }
  let(:seed_encoded_as_json_api) do
    { "id"            => seed.id.to_s,
      "type"          => "seeds",
      "attributes"    => attributes,
      "relationships" => {
        "owner" => owner_as_json_api,
        "crop"  => crop_as_json_api
      } }
  end

  let(:owner_as_json_api) { related_link("members/#{seed.owner_id}") }

  let(:crop_as_json_api) { related_link("crops/#{seed.crop_id}") }

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
    before { get '/api/v1/seeds', params: {}, headers: }

    it { expect(subject['data']).to include(seed_encoded_as_json_api) }
  end

  describe '#show' do
    before { get "/api/v1/seeds/#{seed.id}", params: {}, headers: }

    it { expect(subject['data']['attributes']).to eq(attributes) }
    it { expect(subject['data']['relationships']).to include("owner" => owner_as_json_api) }
    it { expect(subject['data']['relationships']).to include("crop" => crop_as_json_api) }
    it { expect(subject['data']).to eq(seed_encoded_as_json_api) }
  end

  context 'filtering' do
    let!(:seed2) do
      create(:seed, tradable_to: 'nationally', organic: 'certified organic', gmo: 'certified GMO-free', heirloom: 'heirloom')
    end

    it 'filters by crop' do
      get("/api/v1/seeds?filter[crop]=#{seed2.crop.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by tradable_to' do
      get('/api/v1/seeds?filter[tradable_to]=nationally', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by organic' do
      get('/api/v1/seeds?filter[organic]=certified organic', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by gmo' do
      get('/api/v1/seeds?filter[gmo]=certified GMO-free', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by heirloom' do
      get('/api/v1/seeds?filter[heirloom]=heirloom', params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end

    it 'filters by owner' do
      get("/api/v1/seeds?filter[owner_id]=#{seed2.owner.id}", params: {}, headers:)

      expect(response).to have_http_status(:ok)
      expect(subject['data'].size).to eq(1)
      expect(subject['data'][0]['id']).to eq(seed2.id.to_s)
    end
  end

  it_behaves_like 'a resource members can write', 'seeds' do
    let(:create_params) do
      { attributes:    { description: 'My API seed' },
        relationships: { crop: link_to('crops', create(:crop).id) } }
    end
    let(:own_record) { create(:seed, owner: member) }
    let(:other_record) { create(:seed) }
    let(:changes) { { description: 'An updated seed' } }
  end
end
