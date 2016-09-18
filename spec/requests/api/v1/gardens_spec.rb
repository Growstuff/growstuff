# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Gardens' do
  include RequestApiSpecHelpers

  let(:garden) { FactoryGirl.create(:garden) }
  let(:data)   { JSON.parse(response.body).fetch('data') }
  let(:links)  { data['links'] }

  context '#index' do
    before { get '/api/v1/gardens', {}, jsonapi_request_headers }
    it 'responds with HTTP 200 status' do
      expect(response).to have_http_status(:ok)
    end

    it 'has data key' do
      verify_data_key_in_json response.body
    end

    it 'has no gardens' do
      expect(data.length).to eq 0
    end
    it 'has one garden' do
      garden
      expect(data.length).to eq 0
    end
  end

  context '#show' do
    before do
      get  "/api/v1/gardens/#{garden.id}", {}, jsonapi_request_headers
    end

    it 'responds with HTTP 200 status' do
      expect(response).to have_http_status(:ok)
    end
    it 'shows garden data' do
      expect(data['id']).to eq(garden.id.to_s)
      expect(data['attributes']['name']).to eq(garden.name)
      expect(data['attributes']['active']).to eq(garden.active)
    end
    it 'has an owner' do
      expect(data['relationships']).to have_key('owner')
    end
  end

  context 'modifying data' do
    it 'does not allow post' do
      post "/api/v1/gardens/#{garden.id}", {}, jsonapi_request_headers
      expect(response).to have_http_status(:not_found)
    end
    it 'does not allow put' do
      put "/api/v1/gardens/#{garden.id}", {}, jsonapi_request_headers
      expect(response).to have_http_status(:not_found)
    end
    it 'does not allow delete' do
      delete "/api/v1/gardens/#{garden.id}", {}, jsonapi_request_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
