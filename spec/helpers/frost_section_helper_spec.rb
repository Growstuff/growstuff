# frozen_string_literal: true

require 'rails_helper'

describe FrostSectionHelper do
  # The numbers in the design: in the south a frost year is a calendar year, so a day number is days since 1 January.
  def day(month, date)
    (Date.new(2026, month, date) - Date.new(2026, 1, 1)).to_i
  end

  let(:reading) { Struct.new(:date, :temp_min_c) }
  let(:stat) do
    build(:frost_stat, status: 'frost', first_frost_p10: day(6, 4), first_frost_median: day(6, 23),
                       last_frost_median: day(8, 29), last_frost_p90: day(10, 1))
  end
  let(:readings) { [reading.new(Date.new(2026, 8, 20), 3.3)] }
  let(:finished) { false }
  let(:today) { Date.new(2026, 11, 7) }
  let(:frost) do
    PlantingFrost.new(stat:, planted_on: Date.new(2026, 8, 18), ends_on: Date.new(2027, 2, 16), finished:, readings:, today:)
  end

  def missing?(text)
    text.to_s.match?(/translation missing/i)
  end

  describe '#frost_verdict' do
    {
      'before the season soon' => Date.new(2026, 6, 10), 'before the season far off' => Date.new(2026, 1, 10),
      'in the season' => Date.new(2026, 8, 25), 'late but possible' => Date.new(2026, 9, 15), 'passed' => Date.new(2026, 11, 7)
    }.each do |name, date|
      context "when #{name}" do
        let(:today) { date }

        it 'has a headline and a sentence from the locale' do
          verdict = helper.frost_verdict(frost)
          expect([verdict[:title], verdict[:body]].map { |text| text.present? && !missing?(text) }).to eq [true, true]
        end
      end
    end

    context 'when a planting has finished clear' do
      let(:finished) { true }

      it 'has a headline and a sentence from the locale' do
        verdict = helper.frost_verdict(frost)
        expect([verdict[:title], verdict[:body]].map { |text| text.present? && !missing?(text) }).to eq [true, true]
      end
    end

    context 'when a planting still growing has had a frost night' do
      let(:readings) { [reading.new(Date.new(2026, 9, 1), 1.0)] }

      it 'says more than for a planting with no frost night' do
        clear = PlantingFrost.new(stat:, planted_on: Date.new(2026, 8, 18), ends_on: Date.new(2027, 2, 16), finished:,
                                  readings: [reading.new(Date.new(2026, 9, 1), 6.0)], today:)
        expect(helper.frost_verdict(frost)[:body].length).to be > helper.frost_verdict(clear)[:body].length
      end

      it 'adds a sentence from the locale' do
        expect(missing?(helper.frost_verdict(frost)[:body])).to be false
      end
    end

    context 'when a planting has finished with no night temperatures' do
      let(:finished) { true }
      let(:readings) { [] }

      it 'still has a sentence from the locale' do
        expect(missing?(helper.frost_verdict(frost)[:body])).to be false
      end
    end

    context 'when a planting has finished after a frost night' do
      let(:finished) { true }
      let(:readings) { [reading.new(Date.new(2026, 9, 1), 1.0), reading.new(Date.new(2026, 9, 2), 0.5)] }

      it 'has a sentence from the locale' do
        expect(missing?(helper.frost_verdict(frost)[:body])).to be false
      end
    end

    context 'when frost is rare' do
      before { stat.assign_attributes(status: 'rare', first_frost_median: nil, last_frost_median: nil) }

      it 'has a headline and a sentence from the locale' do
        verdict = helper.frost_verdict(frost)
        expect([verdict[:title], verdict[:body]].map { |text| text.present? && !missing?(text) }).to eq [true, true]
      end
    end
  end

  describe '#frost_cards' do
    it 'has four for a planting still growing' do
      expect(helper.frost_cards(frost).size).to eq 4
    end

    context 'when the planting has finished' do
      let(:finished) { true }

      it 'has four, in place of the frost-free season' do
        expect(helper.frost_cards(frost).pluck(:label)).to include(helper.frost_cards(frost)[1][:label])
      end

      it 'has the days it grew through frost danger' do
        expect(helper.frost_cards(frost)[1][:value]).to eq helper.frost_days(45)
      end
    end

    describe 'the coldest night' do
      subject(:card) { helper.frost_cards(frost).first }

      it 'is the temperature itself' do
        expect(card[:value]).to eq '3.3 °C'
      end

      it 'says how far above the frost danger line it stayed' do
        expect(card[:note]).to eq '1.3 °C above the 2 °C frost danger line'
      end

      context 'with a night below the line' do
        let(:readings) { [reading.new(Date.new(2026, 8, 20), 1.1)] }

        it 'says how far below it went' do
          expect(card[:note]).to eq '0.9 °C below the 2 °C frost danger line'
        end
      end

      context 'with a night on the line' do
        let(:readings) { [reading.new(Date.new(2026, 8, 20), 2.0)] }

        it 'says it was right on it' do
          expect(card[:note]).to eq 'Right on the 2 °C frost danger line'
        end
      end
    end

    context 'when the planting has finished with no finish date' do
      let(:finished) { true }
      let(:readings) { [] }
      let(:frost) do
        PlantingFrost.new(stat:, planted_on: Date.new(2016, 9, 3), ends_on: nil, finished:, readings:, today:)
      end

      it 'has only the usual last frost' do
        expect(helper.frost_cards(frost).size).to eq 1
      end
    end

    context 'without night temperatures' do
      let(:readings) { [] }

      it 'leaves out the coldest night' do
        expect(helper.frost_cards(frost).size).to eq 3
      end
    end

    it 'has a value and a note on every card' do
      expect(helper.frost_cards(frost).flat_map { |card| card.values_at(:label, :value, :note) }).to all(be_present)
    end
  end

  describe 'the timeline' do
    it 'tags the usual frost danger with a label' do
      usual = frost.danger_bands.find { |band| band.kind == :usual }
      expect(Capybara.string(helper.frost_band_tag(frost, usual))).to have_css '.frost-band--usual .frost-band-label'
    end

    it 'tags the possible frost danger without a label' do
      possible = frost.danger_bands.find { |band| band.kind == :possible }
      expect(Capybara.string(helper.frost_band_tag(frost, possible))).to have_no_css '.frost-band-label'
    end

    it 'places a band along the timeline as a share of it' do
      usual = frost.danger_bands.find { |band| band.kind == :usual }
      expect(helper.frost_band_tag(frost, usual)).to include "width: #{helper.frost_percent(frost.width(usual))}"
    end

    it 'marks today for a planting still growing' do
      expect(Capybara.string(helper.frost_today_tags(frost))).to have_css '.frost-today-line'
    end

    context 'when the planting has finished' do
      let(:finished) { true }

      it 'does not mark today' do
        expect(helper.frost_today_tags(frost)).to be_nil
      end
    end

    it 'has a tick for every month on the axis' do
      expect(Capybara.string(helper.frost_axis_tags(frost))).to have_css '.frost-tick', count: 14
    end

    it 'names the year at the start of the axis and of each new year' do
      expect(Capybara.string(helper.frost_axis_tags(frost))).to have_css '.frost-year', count: 2
    end

    it 'describes the timeline for a screen reader' do
      expect(missing?(helper.frost_timeline_description(frost))).to be false
    end
  end

  describe '#frost_percent' do
    it 'gives a fraction as a percentage' do
      expect(helper.frost_percent(0.5)).to eq '50.0%'
    end
  end
end
