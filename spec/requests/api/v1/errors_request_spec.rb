# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API errors' do
  include_context 'with an API member'

  let(:garden_params) { { data: { type: 'gardens', attributes: { name: 'A new garden' } } }.to_json }

  describe 'a record that does not exist' do
    before { get '/api/v1/plantings/0', headers: read_headers }

    it { expect(response).to have_http_status(:not_found) }

    it 'responds as JSON:API' do
      expect(response.media_type).to eq('application/vnd.api+json')
    end

    it 'reports the status in the error' do
      expect(json['errors'].first['status']).to eq('404')
    end
  end

  describe 'a filter that does not exist' do
    before { get '/api/v1/plantings?filter[nonsense]=1', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }

    it 'names the filter' do
      expect(json['errors'].first['detail']).to include('nonsense')
    end
  end

  describe 'a filter on a computed attribute' do
    before { get '/api/v1/plantings?filter[crop-name]=beans', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }
  end

  describe 'a page size over the maximum' do
    before { get '/api/v1/plantings?page[limit]=101', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }
  end

  describe 'a resource that fails validation' do
    before do
      token
      post '/api/v1/gardens',
           params:  { data: { type: 'gardens', attributes: { name: '' } } }.to_json,
           headers: auth_headers
    end

    it { expect(response).to have_http_status(:unprocessable_entity) }

    it 'points at the invalid attribute' do
      expect(json['errors'].first['source']['pointer']).to eq('/data/attributes/name')
    end

    it 'does not create the garden' do
      expect(Garden.where(name: '')).to be_empty
    end
  end

  describe 'a write that sets an attribute that does not exist' do
    before do
      token
      post '/api/v1/gardens', params:  { data: { type: 'gardens', attributes: { name: 'A new garden', nonsense: 1 } } }.to_json,
                              headers: auth_headers
    end

    it { expect(response).to have_http_status(:bad_request) }

    it 'does not create the garden' do
      expect(Garden.where(name: 'A new garden')).to be_empty
    end
  end

  describe 'a write that sets an attribute that cannot be written' do
    before do
      token
      post '/api/v1/gardens', params:  { data: { type: 'gardens', attributes: { name: 'A new garden', slug: 'mine' } } }.to_json,
                              headers: auth_headers
    end

    it { expect(response).to have_http_status(:bad_request) }
  end

  describe 'a write with a body that is not shaped like JSON:API' do
    {
      'data that is not an object'           => { data: 'x' },
      'attributes that are not an object'    => { data: { type: 'gardens', attributes: 'x' } },
      'relationships that are not an object' => { data: { type: 'gardens', relationships: 'x' } },
      'a relationship that is not an object' => { data: { type: 'gardens', relationships: { owner: '1' } } },
      'a link that is not an object'         => { data: { type: 'gardens', relationships: { owner: { data: '1' } } } },
      'a list of links for a to-one'         => { data: { type:          'gardens',
                                                          relationships: { owner: { data: [{ type: 'members', id: '1' }] } } } },
      'a link with attributes'               => { data: { type:          'gardens',
                                                          relationships: { owner: { data: { type: 'members', id: '1',
attributes: { x: 1 } } } } } },
      'no data'                              => {}
    }.each do |label, body|
      context "with #{label}" do
        before do
          token
          post '/api/v1/gardens', params: body.to_json, headers: auth_headers
        end

        it { expect(response).to have_http_status(:bad_request) }
      end
    end
  end

  describe 'a resource of the wrong type' do
    before do
      post '/api/v1/gardens',
           params:  { data: { type: 'plantings', attributes: { name: 'A new garden' } } }.to_json,
           headers: auth_headers
    end

    it { expect(response).to have_http_status(:bad_request) }

    it 'does not create the garden' do
      expect(Garden.where(name: 'A new garden')).to be_empty
    end
  end

  describe 'writing without a token' do
    before { post '/api/v1/gardens', params: garden_params, headers: write_headers }

    it { expect(response).to have_http_status(:unauthorized) }

    it 'does not create the garden' do
      expect(Garden.where(name: 'A new garden')).to be_empty
    end
  end

  describe 'writing with a token that does not exist' do
    before { post '/api/v1/gardens', params: garden_params, headers: write_headers.merge('Authorization' => 'Bearer nope') }

    it { expect(response).to have_http_status(:unauthorized) }
  end

  describe 'writing with a token from another provider' do
    before do
      create(:authentication, member: member, provider: 'flickr', token: 'flickr-token')
      post '/api/v1/gardens', params: garden_params, headers: write_headers.merge('Authorization' => 'Bearer flickr-token')
    end

    it { expect(response).to have_http_status(:unauthorized) }
  end

  describe 'reading with a token that does not exist' do
    before { get '/api/v1/crops', headers: read_headers.merge('Authorization' => 'Bearer nope') }

    it 'is still allowed, because reads are public' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'reading without a token' do
    before { get '/api/v1/gardens', headers: read_headers }

    it { expect(response).to have_http_status(:ok) }
  end
end
