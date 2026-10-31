# frozen_string_literal: true

require 'rails_helper'

describe NewFeatures do
  describe '.since' do
    it 'lists features added to the list after the date' do
      expect(described_class.since(Date.new(2026, 10, 30)).map(&:title)).to eq ['Seed library', 'Nursery garden', 'Jobs', 'Weather data']
    end

    it 'leaves out features added on or before the date' do
      expect(described_class.since(Date.new(2026, 10, 31))).to eq []
    end

    it 'links to a route that exists' do
      routes = Rails.application.routes.url_helpers
      expect(described_class::ALL.map { |feature| routes.respond_to?("#{feature.path}_path") }).to all(be true)
    end
  end
end
