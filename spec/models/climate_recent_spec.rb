# frozen_string_literal: true

require 'rails_helper'

describe ClimateRecent do
  it 'is valid from the factory' do
    expect(build(:climate_recent)).to be_valid
  end

  it 'has one row for a cell' do
    create(:climate_recent)
    expect(build(:climate_recent)).not_to be_valid
  end

  describe '.from_days' do
    subject(:recent) { described_class.from_days(readings) }

    # 40 days to 10 October, the first ten at 0 degrees and the rest at 12.
    let(:readings) do
      (Date.new(2026, 9, 1)..Date.new(2026, 10, 10)).index_with { |day| { temp_mean_c: day < Date.new(2026, 9, 11) ? 0.0 : 12.0 } }
    end

    it 'ends on the latest day' do
      expect(recent.ends_on).to eq Date.new(2026, 10, 10)
    end

    it 'starts 29 days before' do
      expect(recent.starts_on).to eq Date.new(2026, 9, 11)
    end

    it 'averages only those days' do
      expect(recent.temp_mean_c).to eq 12.0
    end

    context 'when the latest days have no air temperature' do
      let(:readings) { { Date.new(2026, 10, 9) => { temp_mean_c: 8.0 }, Date.new(2026, 10, 10) => { rainfall_mm: 1.0 } } }

      it 'ends on the latest day with one' do
        expect(recent.ends_on).to eq Date.new(2026, 10, 9)
      end
    end

    context 'with no air temperatures' do
      let(:readings) { { Date.new(2026, 10, 10) => { rainfall_mm: 1.0 } } }

      it { is_expected.to be_nil }
    end
  end
end
