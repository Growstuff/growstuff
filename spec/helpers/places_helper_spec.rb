# frozen_string_literal: true

require 'rails_helper'

describe PlacesHelper do
  describe '#places_map_data' do
    subject(:data) { helper.places_map_data }

    it 'gives the map the marker icon' do
      expect(data[:marker_icon]).to match(%r{spade-marker.*\.svg})
    end

    it 'gives the map the user agent email, unused in tests' do
      expect(data[:user_agent_email]).to eq(0)
    end

    it 'leaves out where the map is centred without a place' do
      expect(data).not_to include(:latitude)
    end

    it 'gives the map where to centre, for a place' do
      expect(helper.places_map_data(latitude: -41.3, longitude: 174.8)).to include(latitude: -41.3, longitude: 174.8)
    end
  end
end
