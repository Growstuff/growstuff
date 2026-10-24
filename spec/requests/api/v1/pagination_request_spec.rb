# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API pagination' do
  include_context 'with an API member'

  let!(:crops) { create_list(:crop, 12) } # rubocop:disable FactoryBot/ExcessiveCreateList -- more than a default page of 10

  # Follows links.next the way RemoteApiClient does, returning the ids of every page in order.
  def ids_from_following_next(path)
    ids = []
    while path
      get path, headers: read_headers
      ids.concat(json['data'].pluck('id'))
      path = json.dig('links', 'next')
    end
    ids
  end

  context 'without page params' do
    before { get '/api/v1/crops', headers: read_headers }

    it 'returns ten records' do
      expect(json['data'].size).to eq(10)
    end

    it 'links to the next page' do
      expect(json['links']).to have_key('next')
    end

    it 'does not link to a previous page' do
      expect(json['links']).not_to have_key('prev')
    end
  end

  context 'with page[limit]' do
    before { get '/api/v1/crops?page[limit]=5', headers: read_headers }

    it 'returns that many records' do
      expect(json['data'].size).to eq(5)
    end
  end

  context 'with page[limit] and page[offset]' do
    before { get '/api/v1/crops?page[limit]=5&page[offset]=10', headers: read_headers }

    it 'returns the records left after the offset' do
      expect(json['data'].size).to eq(2)
    end

    it 'links to the previous page' do
      expect(json['links']).to have_key('prev')
    end

    it 'does not link to a next page' do
      expect(json['links']).not_to have_key('next')
    end
  end

  context 'with page[limit] over the maximum' do
    before { get '/api/v1/crops?page[limit]=1000', headers: read_headers }

    it { expect(response).to have_http_status(:bad_request) }

    it 'explains the maximum' do
      expect(json['errors'].first['detail']).to include('max supported size 100')
    end
  end

  describe 'following links.next' do
    let(:all_ids) { ids_from_following_next('/api/v1/crops?page[limit]=5') }

    it 'visits every record' do
      expect(all_ids).to match_array(crops.map { |crop| crop.id.to_s })
    end

    it 'visits no record twice' do
      expect(all_ids.uniq).to eq(all_ids)
    end
  end

  describe 'with a filter' do
    before { get "/api/v1/crops?filter[id]=#{crops.first.id}&page[limit]=5", headers: read_headers }

    it 'keeps the filter in the links' do
      expect(json['links']['first']).to include('filter%5Bid%5D')
    end
  end

  describe 'crop search' do
    before { get '/api/v1/crops/search', params: { term: 'magic', page: { number: 2, size: 5 } }, headers: read_headers }

    it 'returns the requested page' do
      expect(json['data'].size).to eq(5)
    end

    it 'reports the total record count' do
      expect(json['meta']['record_count']).to eq(12)
    end

    it 'reports the page count' do
      expect(json['meta']['page_count']).to eq(3)
    end
  end
end
