# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API includes and sparse fieldsets' do
  include_context 'with an API member'

  let!(:planting) { create(:planting) }
  let!(:harvest) { create(:harvest, planting: planting, crop: planting.crop, owner: planting.owner) }

  def included_types
    json['included'].pluck('type')
  end

  context 'without include' do
    before { get "/api/v1/plantings/#{planting.id}", headers: read_headers }

    it { expect(json).not_to have_key('included') }
  end

  context 'with include of a relationship' do
    before { get "/api/v1/plantings/#{planting.id}?include=crop", headers: read_headers }

    it { expect(included_types).to eq(['crops']) }

    it 'includes the crop of the planting' do
      expect(json['included'].first['id']).to eq(planting.crop_id.to_s)
    end

    it 'adds linkage data to the included relationship' do
      expect(json['data']['relationships']['crop']['data']).to eq('type' => 'crops', 'id' => planting.crop_id.to_s)
    end
  end

  context 'with include of a garden' do
    before do
      get "/api/v1/plantings/#{planting.id}?include=garden", headers: read_headers
    end

    it 'includes the garden of the planting' do
      expect(json['included'].first['id']).to eq(planting.garden_id.to_s)
    end
  end

  context 'with include on a collection' do
    before { get '/api/v1/plantings?include=crop', headers: read_headers }

    it { expect(included_types).to eq(['crops']) }
  end

  context 'with a nested include' do
    before do
      get '/api/v1/harvests?include=planting.crop', headers: read_headers
    end

    it 'includes the planting and its crop' do
      expect(included_types).to contain_exactly('plantings', 'crops')
    end
  end

  context 'with a relationship that does not exist' do
    before { get "/api/v1/plantings/#{planting.id}?include=nonsense", headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }

    it 'names the relationship' do
      expect(json['errors'].first['detail']).to include('nonsense')
    end
  end

  context 'with fields[plantings]' do
    before { get "/api/v1/plantings/#{planting.id}?fields[plantings]=slug,quantity", headers: read_headers }

    it 'returns only those attributes' do
      expect(json['data']['attributes'].keys).to contain_exactly('slug', 'quantity')
    end
  end

  context 'with fields on a collection' do
    before { get '/api/v1/crops?fields[crops]=name', headers: read_headers }

    it 'returns only that attribute for every record' do
      expect(json['data'].map { |crop| crop['attributes'].keys }.uniq).to eq([['name']])
    end
  end

  context 'with fields on an included type' do
    before { get "/api/v1/plantings/#{planting.id}?include=crop&fields[crops]=name", headers: read_headers }

    it 'limits the included attributes' do
      expect(json['included'].first['attributes'].keys).to eq(['name'])
    end
  end
end
