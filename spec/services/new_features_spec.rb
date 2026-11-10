# frozen_string_literal: true

require 'rails_helper'

describe NewFeatures do
  describe '.since' do
    it 'lists features added to the list after the date' do
      expect(described_class.since(Date.new(2026, 10, 30)).map(&:title)).to eq [
        'Seed library', 'Nursery garden', 'Jobs', 'Weather data', 'Frost danger', 'Optimal climate for plantings'
      ]
    end

    it 'leaves out features added on or before the date' do
      expect(described_class.since(Date.new(2026, 11, 10))).to eq []
    end

    it 'links to a route that exists' do
      routes = Rails.application.routes.url_helpers
      expect(described_class::ALL.map { |feature| routes.respond_to?("#{feature.path}_path") }).to all(be true)
    end
  end

  describe 'Feature#url' do
    let(:routes) do
      Class.new do
        include Rails.application.routes.url_helpers

        def default_url_options = { host: 'example.com' }
      end.new
    end
    let(:frost) { described_class::ALL.find { |feature| feature.title == 'Frost danger' } }

    it 'links to the member\'s own place page' do
      member = build(:member, location: 'Wellington, New Zealand')
      expect(frost.url(member, routes)).to eq routes.place_url('Wellington, New Zealand')
    end

    it 'links to the list of places for a member with no location' do
      expect(frost.url(build(:member, location: nil), routes)).to eq routes.places_url
    end

    it 'links to the route named by the feature otherwise' do
      seeds = described_class::ALL.find { |feature| feature.title == 'Seed library' }
      expect(seeds.url(build(:member), routes)).to eq routes.seeds_url
    end
  end
end
