# frozen_string_literal: true

require 'rails_helper'

describe CropDuration do
  subject(:duration) { described_class.new(highs:, lows:, **figures) }

  # Every month averages 20 °C, so a base of 10 gives 10 degree days a day.
  let(:highs) { (1..12).index_with(25.0) }
  let(:lows) { (1..12).index_with(15.0) }
  let(:figures) { { degree_days: 600, base: 10, quick: 90, slow: 120, median: 70 } }

  def source
    duration.from(3).source
  end

  describe '#from' do
    it 'works out the days from the degree days at the place' do
      expect(duration.from(3).quick).to eq 60
    end

    it 'prefers the degree days to the other figures' do
      expect(source).to eq :degree_days
    end

    context 'without weather for the place' do
      let(:highs) { nil }
      let(:lows) { nil }

      it('falls back to EcoCrop') { expect(source).to eq :ecocrop }
    end

    context 'with a month the weather is missing for' do
      let(:highs) { { 3 => 25.0 } }

      it('falls back to EcoCrop') { expect(source).to eq :ecocrop }
    end

    context 'with a crop that needs more heat than two years give' do
      let(:figures) { { degree_days: 100_000, quick: 90 } }

      it('falls back to EcoCrop') { expect(source).to eq :ecocrop }
    end

    context 'without degree days' do
      let(:figures) { { quick: 90, slow: 120, median: 70 } }

      it('uses EcoCrop') { expect(source).to eq :ecocrop }
      it('gives its longest cycle as the slow figure') { expect(duration.from(3).slow).to eq 120 }
    end

    context 'with a longest cycle of zero' do
      let(:figures) { { quick: 90, slow: 0 } }

      it('takes the shortest for both') { expect(duration.from(3).slow).to eq 90 }
    end

    context 'with a shortest cycle of zero' do
      let(:figures) { { quick: 0, slow: 0, median: 70 } }

      it('falls back to the median') { expect(source).to eq :median }
    end

    context 'with no figures' do
      let(:figures) { {} }

      it('says nothing') { expect(duration.from(3)).to be_nil }
    end

    context 'when the season is cooler at first' do
      let(:highs) { (1..12).index_with { |month| month == 3 ? 15.0 : 25.0 } }
      let(:lows) { (1..12).index_with { |month| month == 3 ? 5.0 : 15.0 } }

      it 'takes longer from the cool month' do
        expect(duration.from(3).quick).to be > duration.from(4).quick
      end
    end
  end
end
