# frozen_string_literal: true

require 'rails_helper'

describe CommunityGarden do
  subject(:community_garden) { build(:community_garden) }

  it { is_expected.to be_valid }

  it 'requires a title' do
    community_garden.title = ''
    expect(community_garden).not_to be_valid
  end

  it 'enforces uniqueness of osm_id' do
    create(:community_garden, osm_id: 'node/123456')
    community_garden.osm_id = 'node/123456'
    expect(community_garden).not_to be_valid
  end

  it 'allows blank osm_id' do
    community_garden.osm_id = nil
    expect(community_garden).to be_valid
  end

  describe '#latitude and #longitude' do
    it 'extracts latitude and longitude from coordinates' do
      community_garden.coordinates = '-37.8136, 144.9631'
      expect(community_garden.latitude).to eq(-37.8136)
      expect(community_garden.longitude).to eq(144.9631)
    end

    it 'returns nil when coordinates are blank' do
      community_garden.coordinates = nil
      expect(community_garden.latitude).to be_nil
      expect(community_garden.longitude).to be_nil
    end
  end
end
