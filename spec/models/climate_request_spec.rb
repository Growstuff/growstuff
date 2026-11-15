# frozen_string_literal: true

require 'rails_helper'

describe ClimateRequest do
  include ActiveSupport::Testing::TimeHelpers

  let(:place) { Place.new(-35.73, 174.32) }

  describe '.record' do
    it 'asks for the cell of the place' do
      described_class.record(place)
      expect(described_class.pluck(:latitude, :longitude)).to eq [[-35.75, 174.25]]
    end

    it 'keeps one request for a cell however many ask' do
      2.times { described_class.record(place) }
      expect(described_class.count).to eq 1
    end

    it 'keeps the time it was first asked' do
      described_class.record(place)
      first = described_class.first.requested_at
      travel_to(1.day.from_now) { described_class.record(place) }
      expect(described_class.first.requested_at).to eq first
    end

    it 'does not ask for a cell we hold weather for' do
      create(:climate_month, latitude: -35.75, longitude: 174.25)
      described_class.record(place)
      expect(described_class.count).to eq 0
    end

    it 'does not ask for a place with no location' do
      described_class.record(Place.new(nil, nil))
      expect(described_class.count).to eq 0
    end
  end

  describe '.waiting' do
    it 'leaves out a cell weather has since arrived for' do
      described_class.record(place)
      create(:climate_month, latitude: -35.75, longitude: 174.25)
      expect(described_class.waiting).to be_empty
    end
  end

  describe '.record_members' do
    before do
      create_located_member('Whangarei, New Zealand', -35.73, 174.32)
      create_located_member('Ngunguru, New Zealand', -35.7, 174.3)
      create_located_member('Paris, France', 48.85, 2.35)
      create(:member)
      described_class.delete_all
    end

    it 'asks once for members who share a cell' do
      described_class.record_members
      expect(described_class.count).to eq 2
    end

    it 'counts the cells it added' do
      expect(described_class.record_members).to eq 2
    end

    it 'adds nothing the second time' do
      described_class.record_members
      expect(described_class.record_members).to eq 0
    end

    it 'leaves out a cell we hold weather for' do
      create(:climate_month, latitude: 48.75, longitude: 2.25)
      expect(described_class.record_members).to eq 1
    end
  end
end
