# frozen_string_literal: true

require 'rails_helper'

describe FrostSeason do
  subject(:season) { described_class.new(stat:, today:) }

  # In the south a frost year is a calendar year, so a day number is days since 1 January.
  def day(month, date)
    (Date.new(2026, month, date) - Date.new(2026, 1, 1)).to_i
  end

  let(:stat) do
    build(:frost_stat, status: 'frost', first_frost_p10: day(6, 4), first_frost_median: day(6, 23),
                       last_frost_median: day(8, 29), last_frost_p90: day(10, 1))
  end
  let(:today) { Date.new(2026, 11, 7) }

  describe '#verdict' do
    {
      Date.new(2026, 4, 1) => :before_season, Date.new(2026, 8, 25) => :in_season,
      Date.new(2026, 9, 15) => :late_possible, Date.new(2026, 11, 7) => :passed
    }.each do |date, verdict|
      context "when on #{date}" do
        let(:today) { date }

        it { expect(season.verdict).to eq verdict }
      end
    end

    context 'with a place with little frost' do
      before { stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil) }

      it { expect(season.verdict).to eq :rare }
    end
  end

  describe 'the dates' do
    it 'has the usual frost danger of this year' do
      expect(season.usual).to eq Date.new(2026, 6, 23)..Date.new(2026, 8, 29)
    end

    it 'starts the next season next year' do
      expect(season.next_season_start).to eq Date.new(2027, 6, 23)
    end

    it 'counts the days to the next season from today' do
      expect(season.days_to_next_season).to eq 228
    end
  end

  describe '#axis' do
    it 'runs from the month of the earliest frost to a month past the next season' do
      expect(season.axis).to eq Date.new(2026, 6, 1)..Date.new(2027, 7, 31)
    end
  end

  describe '#planting_bands' do
    it { expect(season.planting_bands).to be_empty }
  end

  describe '.for' do
    let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations

    it 'is nil without frost dates' do
      expect(described_class.for(garden)).to be_nil
    end

    it 'is a season with them' do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      expect(described_class.for(garden)).to be_a described_class
    end
  end
end
