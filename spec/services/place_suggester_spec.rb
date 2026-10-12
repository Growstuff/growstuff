# frozen_string_literal: true

require 'rails_helper'

describe PlaceSuggester do
  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Geocoder::Lookup::Test.add_stub(
      'Wellington', [
        { 'coordinates' => [-41.2887, 174.7772], 'name' => 'Wellington', 'address' => { 'state' => 'Wellington', 'country' => 'New Zealand' } },
        { 'coordinates' => [26.6, -80.2], 'name' => 'Wellington', 'address' => { 'state' => 'Florida', 'country' => 'United States' } },
        { 'coordinates' => [26.6, -80.2], 'name' => 'Wellington', 'address' => { 'state' => 'Florida', 'country' => 'United States' } }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      [-41.2866, 174.7756], [
        { 'coordinates' => [-41.2866, 174.7756], 'name' => 'Wellington', 'address' => { 'country' => 'New Zealand' } }
      ]
    )
  end

  describe '.search' do
    it 'names each place with its region and country' do
      expect(described_class.search('Wellington').pluck(:name)).to eq ['Wellington, New Zealand', 'Wellington, Florida, United States']
    end

    it 'gives coordinates to save' do
      expect(described_class.search('Wellington').first).to include(latitude: -41.2887, longitude: 174.7772)
    end

    it 'does not search for a single letter' do
      expect(described_class.search('W')).to eq []
    end
  end

  describe '.reverse' do
    it 'names where a position is' do
      expect(described_class.reverse(-41.2866, 174.7756).pluck(:name)).to eq ['Wellington, New Zealand']
    end
  end
end
