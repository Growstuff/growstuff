# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Crops Search' do
  subject { JSON.parse response.body }

  let(:headers) { { 'Accept' => 'application/vnd.api+json' } }
  let!(:cabbage) { create(:crop, name: 'Cabbage', approval_status: 'approved') }
  let!(:apple)   { create(:crop, name: 'Apple', approval_status: 'approved') }

  describe 'GET /api/v1/crops/search' do
    describe 'returns crops matching the search term' do
      before { get '/api/v1/crops/search', params: { term: 'Cabbage' }, headers: headers }

      it { expect(response).to have_http_status(:ok) }
      it { expect(subject['data'].size).to eq(1) }
      it { expect(subject['data'].first['attributes']['name']).to eq('Cabbage') }
    end

    describe 'returns empty data if no crops match' do
      before { get '/api/v1/crops/search', params: { term: 'NonExistent' }, headers: headers }

      it { expect(response).to have_http_status(:ok) }
      it { expect(subject['data']).to be_empty }
    end

    it 'includes meta information' do
      get '/api/v1/crops/search', params: { term: 'Cabbage' }, headers: headers
      expect(subject['meta']).to include('record_count' => 1, 'page_count' => 1)
    end
  end
end
