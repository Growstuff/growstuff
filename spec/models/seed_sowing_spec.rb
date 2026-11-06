# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#valid?' do
  subject(:seed) { build(:seed, **details) }

  let(:details) { {} }

  it { is_expected.to be_valid }
  it('has no months to sow in until it is told') { expect(seed.sow_months).to eq [] }

  describe 'sow_months' do
    context 'with several months' do
      let(:details) { { sow_months: [10, 11, 12, 1, 2] } }

      it('keeps them, in calendar order') { expect(seed.sow_months).to eq [1, 2, 10, 11, 12] }
      it { is_expected.to be_valid }
    end

    context 'with what a form sends: strings, a blank from its hidden field, and repeats' do
      let(:details) { { sow_months: ['', '11', '10', '10'] } }

      it('is the months once each') { expect(seed.sow_months).to eq [10, 11] }
    end

    context 'with a month there is not' do
      let(:details) { { sow_months: [13] } }

      it { is_expected.not_to be_valid }
    end

    context 'with a month of zero, which is what text turns into' do
      let(:details) { { sow_months: ['spring'] } }

      it { is_expected.not_to be_valid }
    end

    context 'when saved' do
      let(:details) { { sow_months: [3, 4] } }

      it('comes back as the months') { expect(described_class.find(create(:seed, sow_months: [4, 3]).id).sow_months).to eq [3, 4] }
    end
  end

  describe 'germination' do
    context 'with a range of days' do
      let(:details) { { germination_days_min: 7, germination_days_max: 14 } }

      it { is_expected.to be_valid }
    end

    context 'with fewer than none' do
      let(:details) { { germination_days_min: -1 } }

      it { is_expected.not_to be_valid }
    end

    context 'with part of a day' do
      let(:details) { { germination_days_max: 2.5 } }

      it { is_expected.not_to be_valid }
    end
  end

  describe 'how_to_sow' do
    context 'with what the packet says' do
      let(:details) { { how_to_sow: "Place seeds 6-8cm apart.\nCover to a depth of 2cm." } }

      it { is_expected.to be_valid }
    end

    context 'with far too much' do
      let(:details) { { how_to_sow: 'a' * 2_001 } }

      it { is_expected.not_to be_valid }
    end
  end
end
