# frozen_string_literal: true

require 'rails_helper'

describe PlantingFrost do
  subject(:frost) { described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:, today:) }

  # The numbers in the design: in the south a frost year is a calendar year, so a day number is days since 1 January.
  def day(month, date)
    (Date.new(2026, month, date) - Date.new(2026, 1, 1)).to_i
  end

  let(:reading) { Struct.new(:date, :temp_min_c) }
  let(:stat) do
    build(:frost_stat, status: 'frost', first_frost_p10: day(6, 4), first_frost_median: day(6, 23),
                       last_frost_median: day(8, 29), last_frost_p90: day(10, 1))
  end
  let(:planted_on) { Date.new(2026, 8, 18) }
  let(:ends_on) { Date.new(2027, 2, 16) }
  let(:finished) { false }
  let(:today) { Date.new(2026, 11, 7) }
  let(:readings) { [reading.new(Date.new(2026, 8, 20), 3.3), reading.new(Date.new(2026, 9, 10), 6.0)] }

  describe '#verdict' do
    it 'is before the season ahead of the usual first frost' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 6, 10)).verdict).to eq :before_season
    end

    it 'is in the season between the usual first and last frost' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 8, 25)).verdict).to eq :in_season
    end

    it 'is late but possible between the usual last frost and the latest' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 9, 15)).verdict).to eq :late_possible
    end

    it 'is passed after the latest it has come' do
      expect(frost.verdict).to eq :passed
    end

    it 'is rare for a place with little frost' do
      stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil)
      expect(frost.verdict).to eq :rare
    end

    context 'when the planting has finished without a frost night' do
      let(:finished) { true }

      it { expect(frost.verdict).to eq :finished_clear }
    end

    context 'when the planting has finished after a frost night' do
      let(:finished) { true }
      let(:readings) { [reading.new(Date.new(2026, 9, 1), 1.5)] }

      it { expect(frost.verdict).to eq :finished_hit }
    end
  end

  describe 'the dates' do
    it 'has the usual frost danger' do
      expect(frost.usual).to eq Date.new(2026, 6, 23)..Date.new(2026, 8, 29)
    end

    it 'has the possible frost danger' do
      expect(frost.possible).to eq Date.new(2026, 6, 4)..Date.new(2026, 10, 1)
    end

    it 'has the start of the next season' do
      expect(frost.next_season_start).to eq Date.new(2027, 6, 23)
    end

    it 'counts the days it was planted before the usual last frost' do
      expect(frost.planted_days_before_usual_end).to eq 11
    end

    it 'counts the days since the latest it has come' do
      expect(frost.days_since_latest).to eq 37
    end

    it 'counts the days the planting lived inside the possible frost danger' do
      expect(frost.days_in_danger).to eq 45
    end

    it 'counts no days in danger for a planting after the latest it has come' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on: Date.new(2026, 11, 1), ends_on:, finished:, readings:,
                                 today:).days_in_danger).to eq 0
    end

    it 'stops counting days in danger when the planting finishes' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on: Date.new(2026, 9, 1), finished: true, readings:,
                                 today:).days_in_danger).to eq 15
    end

    it 'counts the days from the end of the planting to the next season' do
      expect(frost.days_to_next_season).to eq 127
    end

    it 'counts the days until the usual first frost' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 6, 10)).days_until_usual_start).to eq 13
    end

    it 'counts the days until the usual last frost' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 8, 25)).days_until_usual_end).to eq 4
    end

    it 'counts the days until the latest' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished:, readings:,
                                 today: Date.new(2026, 9, 15)).days_until_latest).to eq 16
    end

    it 'uses the frost year of the planting date in the north' do
      stat.latitude = 51.5
      expect(described_class.new(stat:, crop_name: 'viola', planted_on: Date.new(2026, 12, 1), ends_on: Date.new(2027, 3, 1), finished:,
                                 readings:, today:).usual.first.year).to eq 2026
    end

    context 'without an end to the planting' do
      let(:ends_on) { nil }

      it 'ends today' do
        expect(frost.ends_on).to eq today
      end
    end
  end

  describe 'what the planting went through' do
    it 'finds the coldest night' do
      expect(frost.coldest_night_c).to eq 3.3
    end

    it 'finds the margin above the frost danger temperature' do
      expect(frost.margin_c).to eq 1.3
    end

    it 'counts no frost nights' do
      expect(frost.frost_nights).to eq 0
    end

    context 'with a night at the frost danger temperature' do
      let(:readings) { [reading.new(Date.new(2026, 9, 1), 2.0)] }

      it 'counts it' do
        expect(frost.frost_nights).to eq 1
      end

      it 'has no margin left' do
        expect(frost.margin_c).to eq 0.0
      end
    end

    context 'with readings outside the planting' do
      let(:readings) { [reading.new(Date.new(2026, 8, 1), -3.0), reading.new(Date.new(2026, 9, 1), 5.0)] }

      it 'leaves them out' do
        expect(frost.coldest_night_c).to eq 5.0
      end
    end

    context 'with a cold night outside the frost danger season' do
      let(:readings) { [reading.new(Date.new(2027, 1, 5), -1.0), reading.new(Date.new(2026, 9, 1), 5.0)] }

      it 'leaves it out' do
        expect(frost.coldest_night_c).to eq 5.0
      end
    end

    context 'when the planting is still growing past its expected end' do
      let(:ends_on) { Date.new(2026, 8, 25) }
      let(:readings) { [reading.new(Date.new(2026, 9, 10), 6.0)] }

      it 'counts the nights since' do
        expect(frost.coldest_night_c).to eq 6.0
      end

      it 'counts the days in danger up to the latest it has come' do
        expect(frost.days_in_danger).to eq 45
      end
    end

    context 'when the planting has finished before some nights' do
      let(:finished) { true }
      let(:ends_on) { Date.new(2026, 8, 25) }
      let(:readings) { [reading.new(Date.new(2026, 9, 10), 6.0)] }

      it 'leaves out the nights after it' do
        expect(frost.coldest_night_c).to be_nil
      end
    end

    context 'with no readings' do
      let(:readings) { [] }

      it 'has no margin' do
        expect(frost.margin_c).to be_nil
      end
    end

    context 'with a reading that has no minimum' do
      let(:readings) { [reading.new(Date.new(2026, 9, 1), nil)] }

      it 'leaves it out' do
        expect(frost.coldest_night_c).to be_nil
      end
    end
  end

  describe 'the timeline' do
    it 'covers whole months from the earliest frost to a month after the next season starts' do
      expect(frost.axis).to eq Date.new(2026, 6, 1)..Date.new(2027, 7, 31)
    end

    it 'starts at the planting if that is earlier than the earliest frost' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on: Date.new(2026, 3, 10), ends_on:, finished:, readings:,
                                 today:).axis.first).to eq Date.new(2026, 3, 1)
    end

    it 'runs to the end of the planting if that is later than the next season' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on: Date.new(2027, 11, 15), finished:, readings:,
                                 today:).axis.last).to eq Date.new(2027, 11, 30)
    end

    it 'draws the frost danger of this season and the start of the next' do
      expect(frost.danger_bands.map(&:kind)).to eq %i(possible usual possible possible usual)
    end

    it 'cuts the next season to the axis' do
      expect(frost.danger_bands.last.to).to eq frost.axis.last
    end

    it 'draws a planting still growing as so far and still to come' do
      expect(frost.planting_bands.map(&:kind)).to eq %i(so_far still_to_come)
    end

    it 'draws a planting that has finished as one bar' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on:, finished: true, readings:,
                                 today:).planting_bands.map(&:kind)).to eq [:finished]
    end

    it 'has nothing still to come once the end has passed' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on: Date.new(2026, 10, 31), finished:, readings:,
                                 today:).planting_bands.map(&:kind)).to eq [:so_far]
    end

    it 'puts the start of the axis at nothing' do
      expect(frost.position(frost.axis.first)).to eq 0.0
    end

    it 'puts the end of the axis at everything' do
      expect(frost.position(frost.axis.last + 1)).to eq 1.0
    end

    it 'keeps dates off the axis at the edge' do
      expect(frost.position(Date.new(2030, 1, 1))).to eq 1.0
    end

    it 'gives a band the share of the axis it covers' do
      usual = frost.danger_bands.find { |band| band.kind == :usual }
      expect(frost.width(usual)).to be_within(0.0001).of(68.0 / 426)
    end
  end

  context 'with a perennial planted years ago, with no expected end' do
    let(:planted_on) { Date.new(2019, 12, 31) }
    let(:ends_on) { nil }
    let(:readings) { [reading.new(Date.new(2026, 8, 20), 3.3)] }

    it 'is long lived' do
      expect(frost).to be_long_lived
    end

    it 'has no end ahead' do
      expect(frost).not_to be_end_ahead
    end

    it 'goes by the current frost season, not the one it went in during' do
      expect(frost.usual).to eq Date.new(2026, 6, 23)..Date.new(2026, 8, 29)
    end

    it 'is passed, as today is after the latest it has come' do
      expect(frost.verdict).to eq :passed
    end

    it 'counts the days to the next season from today' do
      expect(frost.days_to_next_season).to eq 228
    end

    it 'covers only the last year on the timeline' do
      expect(frost.axis.first).to eq Date.new(2025, 11, 1)
    end

    it 'draws the planting from the start of the timeline' do
      expect(frost.planting_bands.first.from).to eq Date.new(2025, 11, 7)
    end

    it 'keeps the real planting date' do
      expect(frost.planted_on).to eq Date.new(2019, 12, 31)
    end

    it 'finds the coldest night of its last year' do
      expect(frost.coldest_night_c).to eq 3.3
    end

    it 'counts only the days in danger of its last year' do
      expect(frost.days_in_danger).to eq 120
    end
  end

  context 'with a planting under a year old' do
    it 'is not long lived' do
      expect(frost).not_to be_long_lived
    end

    it 'has an end ahead' do
      expect(frost).to be_end_ahead
    end

    context 'when it has finished' do
      let(:finished) { true }

      it 'has no end ahead' do
        expect(frost).not_to be_end_ahead
      end
    end

    context 'when it has outlived its expected end' do
      let(:ends_on) { Date.new(2026, 10, 1) }

      it 'has no end ahead' do
        expect(frost).not_to be_end_ahead
      end
    end
  end

  describe '.for' do
    let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 8, 18)) }

    it 'is nil when the cell has no frost dates' do
      expect(described_class.for(planting, readings: [])).to be_nil
    end

    it 'is nil when the cell is unknown' do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C, status: 'unknown')
      expect(described_class.for(planting, readings: [])).to be_nil
    end

    it 'is a planting frost when the cell has frost dates' do
      create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C)
      expect(described_class.for(planting, readings: [])).to be_a described_class
    end
  end

  context 'when the planting has finished and there is no finish date, or a predicted one' do
    let(:ends_on) { nil }
    let(:finished) { true }
    let(:planted_on) { Date.new(2016, 9, 3) }

    it 'has no end to go by' do
      expect(frost).to be_end_unknown
    end

    it 'has a verdict that says so' do
      expect(frost.verdict).to eq :finished_undated
    end

    it 'looks at the season it went in' do
      expect(frost.usual.first.year).to eq 2016
    end

    it 'draws the planting as a marker on the day it went in' do
      expect(frost.planting_bands.map(&:kind)).to eq [:planted]
    end

    it 'is not the same as a finish that is predicted' do
      expect(described_class.new(stat:, crop_name: 'viola', planted_on:, ends_on: Date.new(2017, 1, 1), finished:, readings:,
                                 today:)).not_to be_end_unknown
    end
  end

  context 'when the planting began in a nursery that is safe from frost' do
    subject(:frost) do
      described_class.new(stat:, crop_name: 'viola', planted_on: Date.new(2026, 9, 5), sown_on: Date.new(2026, 8, 10), ends_on:,
                          finished:, readings:, today:)
    end

    it 'began in a nursery' do
      expect(frost).to be_from_nursery
    end

    it 'draws the days in the nursery before the days outdoors' do
      expect(frost.planting_bands.map(&:kind)).to eq %i(nursery so_far still_to_come)
    end

    it 'ends the nursery the day before it went outdoors' do
      expect(frost.planting_bands.first.to).to eq Date.new(2026, 9, 4)
    end

    it 'judges the planting by the day it went outdoors' do
      expect(frost.planted_days_before_usual_end).to eq(-7)
    end

    it 'counts the days in danger from the day it went outdoors' do
      expect(frost.days_in_danger).to eq 27
    end

    it 'covers the nursery days on the timeline' do
      expect(frost.axis.cover?(Date.new(2026, 8, 10))).to be true
    end
  end

  describe 'the bands the timeline cuts off' do
    it 'knows where a band really ends' do
      expect(frost.danger_bands.last.last).to be > frost.axis.last
    end

    it 'is open' do
      expect(frost.danger_bands.last).to be_open
    end

    it 'is closed for a band that fits' do
      expect(frost.danger_bands.first).not_to be_open
    end
  end
end
