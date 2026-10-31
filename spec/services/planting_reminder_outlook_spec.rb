# frozen_string_literal: true

require 'rails_helper'

describe PlantingReminderOutlook do
  subject(:outlook) { described_class.new(member, today:) }

  let(:today) { Date.new(2026, 10, 26) }
  let(:member) { create(:member) }

  context 'without a location' do
    before { member.update_columns(latitude: nil, longitude: nil) }

    it { is_expected.not_to be_located }
    it { expect(outlook.season).to be_nil }
    it { expect(outlook.recent).to eq [] }
    it { expect(outlook.soil).to be_nil }
    it { expect(outlook.crops).to eq [] }
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
  end
end
