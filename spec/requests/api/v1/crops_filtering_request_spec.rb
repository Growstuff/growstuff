# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API crop filtering' do
  include_context 'with an API member'

  let!(:approved) { create(:crop, name: 'Approved crop') }
  let!(:pending_crop) { create(:crop, name: 'Pending crop', approval_status: 'pending') }
  let!(:rejected) { create(:crop, name: 'Rejected crop', approval_status: 'rejected', reason_for_rejection: 'Not a crop') }

  def ids
    json['data'].pluck('id')
  end

  context 'without a filter' do
    before { get '/api/v1/crops', headers: read_headers }

    it 'lists only approved crops' do
      expect(ids).to eq([approved.id.to_s])
    end
  end

  context 'with filter[approval-status]' do
    before { get '/api/v1/crops?filter[approval-status]=pending', headers: read_headers }

    it 'lists crops with that status instead' do
      expect(ids).to eq([pending_crop.id.to_s])
    end
  end

  context 'with filter[id]' do
    let!(:second) { create(:crop) }

    before { get "/api/v1/crops?filter[id]=#{approved.id},#{second.id}", headers: read_headers }

    it 'lists the crops with those ids' do
      expect(ids).to contain_exactly(approved.id.to_s, second.id.to_s)
    end
  end

  context 'when showing a crop that is not approved' do
    before { get "/api/v1/crops/#{pending_crop.id}", headers: read_headers }

    it { expect(response).to have_http_status(:not_found) }
  end

  context 'when searching' do
    before { get '/api/v1/crops/search', params: { term: 'crop' }, headers: read_headers }

    it 'finds only approved crops' do
      expect(ids).to eq([approved.id.to_s])
    end
  end
end
