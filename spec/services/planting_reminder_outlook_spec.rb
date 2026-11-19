# frozen_string_literal: true

require 'rails_helper'

describe PlantingReminderOutlook do
  subject(:outlook) { described_class.new(member, today:) }

  let(:today) { Date.new(2026, 10, 26) }
  let(:member) { create(:member) }

  describe '#new_features' do
    before { member.update_columns(created_at: Date.new(2025, 1, 1)) }

    it 'lists what was added since the last reminder' do
      member.update_columns(planting_reminder_sent_at: Date.new(2026, 10, 20))
      expect(outlook.new_features.map(&:title)).to eq [
        'Seed library', 'Nursery garden', 'Jobs', 'Weather data', 'Frost danger', 'Optimal climate for plantings',
        'Link plantings to their seeds', 'Seed packet data', 'Volunteer plantings', 'Growing requirements', 'Gardens safe from frost'
      ]
    end

    it 'is empty when the last reminder came after every feature' do
      member.update_columns(planting_reminder_sent_at: Date.new(2026, 11, 10))
      expect(outlook.new_features).to eq []
    end

    it 'counts from when they joined if they never had a reminder' do
      member.update_columns(created_at: Date.new(2026, 11, 10))
      expect(outlook.new_features).to eq []
    end
  end

  context 'without a location' do
    before { member.update_columns(latitude: nil, longitude: nil) }

    it { is_expected.not_to be_located }
    it { expect(outlook.season).to be_nil }
    it { expect(outlook.recent).to eq [] }
    it { expect(outlook.soil).to be_nil }
    it { expect(outlook.crops).to eq [] }
    it { expect(outlook.climate).to be_nil }
    it { is_expected.not_to be_warm_spell }
    it { is_expected.not_to be_cold_spell }
  end

  context 'with a location' do
    before { member.update_columns(latitude: -41.3, longitude: 174.7) }

    def reading(date, **attributes)
      create(:weather_reading, date:, **attributes)
    end

    it { is_expected.to be_located }
    it { expect(outlook.season).to eq :spring }

    it 'reads the last two weeks, up to yesterday' do
      reading(today - 15)
      kept = [reading(today - 14), reading(today - 1)]
      reading(today)
      expect(outlook.recent).to eq kept
    end

    it 'reads the next two weeks from the same days a year ago' do
      reading(today.prev_year - 1)
      kept = [reading(today.prev_year), reading(today.prev_year + 13)]
      reading(today.prev_year + 14)
      expect(outlook.expected).to eq kept
    end

    it 'finds the newest soil temperature' do
      reading(today - 9, soil_temp_c: 9.0)
      newest = reading(today - 6, soil_temp_c: 11.0)
      reading(today - 2, soil_temp_c: nil)
      expect(outlook.soil).to eq newest
    end

    it 'leaves out weather from other places' do
      reading(today - 1, latitude: 10.0, longitude: 10.0)
      expect(outlook.recent).to eq []
    end

    it 'suggests what gardeners at that latitude are sowing' do
      crop = create(:crop)
      neighbour = create(:garden)
      neighbour.update_columns(latitude: -40.0, longitude: 174.0)
      create(:planting, crop:, garden: neighbour, owner: neighbour.owner, planted_at: Date.new(2024, 10, 3))
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      expect(outlook.crops).to eq [crop]
    end

    describe 'a warm or cold spell' do
      # Two past years of 10 degrees in every month, and the 30 days to 25 October at the cell the member is in.
      before do
        [2024, 2025].each do |year|
          (1..12).each { |month| create(:climate_month, latitude: -41.25, longitude: 174.75, year:, month:, temp_mean_c: 10.0) }
        end
        create(:climate_recent, latitude: -41.25, longitude: 174.75, starts_on: today - 30, ends_on: today - 1, temp_mean_c: recent_mean)
      end

      context 'with the last 30 days more than a degree above usual' do
        let(:recent_mean) { 11.1 }

        it { is_expected.to be_warm_spell }
        it { is_expected.not_to be_cold_spell }
        it { is_expected.to be_spell }
      end

      context 'with the last 30 days exactly a degree above usual' do
        let(:recent_mean) { 11.0 }

        it { is_expected.not_to be_warm_spell }
      end

      context 'with the last 30 days more than a degree colder than usual' do
        let(:recent_mean) { 8.9 }

        it { is_expected.to be_cold_spell }
        it { is_expected.not_to be_warm_spell }
        it { is_expected.to be_spell }
      end

      context 'with the last 30 days exactly a degree colder than usual' do
        let(:recent_mean) { 9.0 }

        it { is_expected.not_to be_cold_spell }
        it { is_expected.not_to be_spell }
      end
    end

    context 'without climate data for the place' do
      it { is_expected.not_to be_spell }
    end
  end
end
