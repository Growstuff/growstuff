# frozen_string_literal: true

require 'rails_helper'

describe FrostCalculator, type: :service do
  subject(:calculator) { described_class.new(readings, latitude:) }

  # Every day of the span is 10 degrees unless a frost is listed.
  def series(from, to, frosts: {})
    (from..to).index_with { |day| frosts.fetch(day, 10.0) }
  end

  context 'with a Northern Hemisphere year, July to June' do
    let(:latitude) { 51.5 }
    let(:readings) do
      series(Date.new(2023, 7, 1), Date.new(2024, 6, 30),
             frosts: { Date.new(2023, 10, 20) => -1.0, Date.new(2024, 1, 5) => -4.0, Date.new(2024, 4, 10) => 0.0 })
    end

    it 'names the year for the calendar year it ends in' do
      expect(calculator.years.map(&:year)).to eq [2024]
    end

    it 'finds the first frost in autumn' do
      expect(calculator.years.first.first_frost).to eq Date.new(2023, 10, 20)
    end

    it 'finds the last frost in spring' do
      expect(calculator.years.first.last_frost).to eq Date.new(2024, 4, 10)
    end

    it 'counts a minimum exactly at the threshold as frost' do
      expect(calculator.years.first.frost?).to be true
    end

    it 'records the lowest minimum' do
      expect(calculator.years.first.lowest_c).to eq(-4.0)
    end
  end

  context 'with a Southern Hemisphere year, January to December' do
    let(:latitude) { -41.3 }
    let(:readings) do
      series(Date.new(2023, 1, 1), Date.new(2023, 12, 31),
             frosts: { Date.new(2023, 5, 25) => -0.5, Date.new(2023, 9, 12) => -1.0 })
    end

    it 'uses the calendar year' do
      expect(calculator.years.map(&:year)).to eq [2023]
    end

    it 'finds the first frost in autumn' do
      expect(calculator.years.first.first_frost).to eq Date.new(2023, 5, 25)
    end

    it 'finds the last frost in spring' do
      expect(calculator.years.first.last_frost).to eq Date.new(2023, 9, 12)
    end
  end

  context 'with a partial year' do
    let(:latitude) { -41.3 }
    let(:readings) { series(Date.new(2023, 1, 1), Date.new(2023, 8, 31), frosts: { Date.new(2023, 5, 25) => -2.0 }) }

    it 'leaves the year out' do
      expect(calculator.years).to be_empty
    end

    it 'reports an unknown status' do
      expect(calculator.summary.status).to eq :unknown
    end
  end

  context 'with a gap in an otherwise complete year' do
    let(:latitude) { -41.3 }
    let(:readings) { series(Date.new(2023, 1, 1), Date.new(2023, 12, 31)).except(Date.new(2023, 6, 1)) }

    it 'leaves the year out' do
      expect(calculator.years).to be_empty
    end
  end

  context 'with a gap in a year and a tolerance for missing days' do
    subject(:calculator) { described_class.new(readings, latitude:, max_missing_days: 3) }

    let(:latitude) { -41.3 }
    let(:readings) do
      series(Date.new(2023, 1, 1), Date.new(2023, 12, 31), frosts: { Date.new(2023, 7, 1) => -1.0 }).except(Date.new(2023, 6, 1))
    end

    it 'uses the year' do
      expect(calculator.years.map(&:year)).to eq [2023]
    end
  end

  context 'with a frost-free place' do
    let(:latitude) { 1.3 }
    let(:readings) { (2015..2024).map { |year| series(Date.new(year, 1, 1), Date.new(year, 12, 31)) }.reduce(:merge) }

    it 'has the rare status' do
      expect(calculator.summary.status).to eq :rare
    end

    it 'gives no dates' do
      expect(calculator.summary.last_frost_median).to be_nil
    end
  end

  context 'with ten Southern Hemisphere years that all have frost' do
    let(:latitude) { -41.3 }
    let(:readings) do
      (2010..2019).map do |year|
        # The last frost slips a day later each year, from 10 September.
        series(Date.new(year, 1, 1), Date.new(year, 12, 31),
               frosts: { Date.new(year, 5, 20) => -1.0, Date.new(year, 9, 10) + (year - 2010) => -1.0 })
      end.reduce(:merge)
    end

    let(:summary) { calculator.summary }

    it 'has the frost status' do
      expect(summary.status).to eq :frost
    end

    it 'uses all the years' do
      expect(summary.years_used).to eq 10
    end

    it 'gives the median last frost as a date, rounding the half day up' do
      expect(calculator.date_for(summary.last_frost_median, 2019)).to eq Date.new(2019, 9, 15)
    end

    it 'puts the safe-to-plant date after the median last frost' do
      expect(summary.last_frost_p90).to be > summary.last_frost_median
    end

    it 'gives the median first frost as a date' do
      expect(calculator.date_for(summary.first_frost_median, 2019)).to eq Date.new(2019, 5, 20)
    end

    it 'counts the frost-free days from one last frost to the next first frost' do
      expect(summary.frost_free_days_median).to be_within(2).of(250)
    end
  end

  context 'with frost in only half the years' do
    let(:latitude) { -41.3 }
    let(:readings) do
      (2010..2019).map do |year|
        series(Date.new(year, 1, 1), Date.new(year, 12, 31), frosts: year.even? ? { Date.new(year, 7, 1) => -1.0 } : {})
      end.reduce(:merge)
    end

    it 'has the possible status' do
      expect(calculator.summary.status).to eq :possible
    end
  end

  describe '.percentile' do
    it 'interpolates between values' do
      expect(described_class.percentile([0, 10], 50)).to eq 5.0
    end

    it 'returns the only value of a single-item list' do
      expect(described_class.percentile([7], 90)).to eq 7.0
    end
  end
end
