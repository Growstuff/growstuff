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
  end
end
