# frozen_string_literal: true

require 'rails_helper'

# The API speaks dashes (`planted-at`), where Graphiti works in underscores.
RSpec.describe 'API dashed names' do
  include_context 'with an API member'

  let!(:garden) { create(:garden, owner: member) }
  let!(:planting) { create(:planting, owner: member, garden: garden, planted_from: 'seed', planted_at: '2020-02-03') }
  let(:crop) { create(:crop) }
  let(:planting_relationships) do
    { crop: { data: { type: 'crops', id: crop.id.to_s } }, garden: { data: { type: 'gardens', id: garden.id.to_s } } }
  end

  def post_planting(attributes)
    post '/api/v1/plantings', params:  { data: { type: 'plantings', attributes:, relationships: planting_relationships } }.to_json,
                              headers: auth_headers
  end

  describe 'attributes in a response' do
    before { get "/api/v1/plantings/#{planting.id}", headers: read_headers }

    it 'are dashed' do
      expect(json['data']['attributes']).to include('planted-at' => '2020-02-03', 'planted-from' => 'seed')
    end

    it 'have no underscores' do
      expect(json['data']['attributes'].keys.grep(/_/)).to be_empty
    end
  end

  describe 'attributes in a request' do
    before { post_planting('planted-at' => '2021-04-05', 'planted-from' => 'cutting') }

    it 'are saved' do
      expect(Planting.last).to have_attributes(planted_at: Date.new(2021, 4, 5), planted_from: 'cutting')
    end

    it 'come back dashed' do
      expect(json['data']['attributes']).to include('planted-at' => '2021-04-05')
    end
  end

  describe 'a validation error on a dashed attribute' do
    before { post_planting('planted-from' => 'nonsense') }

    it { expect(response).to have_http_status(:unprocessable_entity) }

    it 'points at the dashed name' do
      expect(json['errors'].first['source']['pointer']).to eq('/data/attributes/planted-from')
    end
  end

  describe 'filtering' do
    before { get '/api/v1/plantings?filter[planted-from]=seed', headers: read_headers }

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'filtering on a dashed name with an operator' do
    before { get '/api/v1/plantings?filter[planted-at][gt]=2020-01-01', headers: read_headers }

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'sparse fieldsets' do
    before { get "/api/v1/plantings/#{planting.id}?fields[plantings]=planted-at,crop-name", headers: read_headers }

    it 'return the dashed attributes asked for' do
      expect(json['data']['attributes'].keys).to contain_exactly('planted-at', 'crop-name')
    end
  end

  describe 'a relationship named as a filter' do
    before { get "/api/v1/plantings?filter[garden]=#{garden.id}", headers: read_headers }

    it 'filters by its id' do
      expect(ids).to eq([planting.id.to_s])
    end
  end
end
