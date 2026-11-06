# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API sorting' do
  include_context 'with an API member'

  let!(:cherry) { create(:crop, name: 'Cherry') }
  let!(:apple)  { create(:crop, name: 'Apple') }
  let!(:banana) { create(:crop, name: 'Banana') }

  def names
    json['data'].map { |crop| crop['attributes']['name'] }
  end

  context 'with sort=name' do
    before { get '/api/v1/crops?sort=name', headers: read_headers }

    it { expect(names).to eq(%w(Apple Banana Cherry)) }
  end

  context 'with sort=-name' do
    before { get '/api/v1/crops?sort=-name', headers: read_headers }

    it { expect(names).to eq(%w(Cherry Banana Apple)) }
  end

  context 'with sort=id' do
    before { get '/api/v1/crops?sort=id', headers: read_headers }

    it 'orders by id' do
      expect(json['data'].pluck('id')).to eq([cherry, apple, banana].map { |crop| crop.id.to_s })
    end
  end

  context 'with sort=-id' do
    before { get '/api/v1/crops?sort=-id', headers: read_headers }

    it 'orders by descending id' do
      expect(json['data'].pluck('id')).to eq([banana, apple, cherry].map { |crop| crop.id.to_s })
    end
  end

  context 'with two sort fields' do
    let!(:second_apple) { create(:crop, name: 'Apple') }

    before { get '/api/v1/crops?sort=name,-id', headers: read_headers }

    it 'breaks ties with the second field' do
      expect(json['data'].pluck('id').first(2)).to eq([second_apple, apple].map { |crop| crop.id.to_s })
    end
  end

  context 'with a dasherised attribute' do
    let!(:early) { create(:planting, planted_at: '2020-01-01') }
    let!(:late)  { create(:planting, planted_at: '2021-01-01') }

    before { get '/api/v1/plantings?sort=-planted-at', headers: read_headers }

    it 'sorts by that attribute' do
      expect(json['data'].pluck('id').first(2)).to eq([late, early].map { |planting| planting.id.to_s })
    end
  end

  context 'without sort' do
    before { get '/api/v1/crops', headers: read_headers }

    it 'orders by id' do
      expect(json['data'].pluck('id')).to eq([cherry, apple, banana].map { |crop| crop.id.to_s })
    end
  end

  context 'with a computed attribute' do
    before { get '/api/v1/plantings?sort=crop-name', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }
  end

  context 'with a field that cannot be sorted on' do
    before { get '/api/v1/crops?sort=nonsense', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }

    it 'names the field' do
      expect(json['errors'].first['detail']).to include('nonsense')
    end
  end
end
