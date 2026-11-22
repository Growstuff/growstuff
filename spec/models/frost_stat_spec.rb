# frozen_string_literal: true

require 'rails_helper'

describe FrostStat do
  subject(:stat) { build(:frost_stat) }

  it { is_expected.to be_valid }

  describe 'uniqueness' do
    before { create(:frost_stat) }

    it 'allows one row per cell and threshold' do
      expect(build(:frost_stat)).not_to be_valid
    end

    it 'allows another threshold in the same cell' do
      expect(build(:frost_stat, threshold_c: 2.0)).to be_valid
    end
  end

  describe '#date_for' do
    it 'counts from the start of a Southern Hemisphere frost year' do
      expect(stat.date_for(:last_frost_median, 2024)).to eq Date.new(2024, 9, 7)
    end

    it 'counts from July before the year in the Northern Hemisphere' do
      stat.latitude = 51.5
      expect(stat.date_for(:last_frost_median, 2024)).to eq Date.new(2024, 3, 7)
    end

    it 'is nil when there is no date' do
      stat.last_frost_median = nil
      expect(stat.date_for(:last_frost_median, 2024)).to be_nil
    end
  end

  describe '#dated?' do
    it 'is true when there are dates' do
      expect(stat).to be_dated
    end

    it 'is false for a rare cell' do
      expect(build(:frost_stat, status: 'rare', last_frost_median: nil)).not_to be_dated
    end
  end
end
