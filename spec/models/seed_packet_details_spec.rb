# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#valid?' do
  subject(:seed) { build(:seed, **details) }

  let(:details) { {} }

  it { is_expected.to be_valid }

  context 'with a row spacing' do
    let(:details) { { row_spacing: 50 } }

    it { is_expected.to be_valid }
  end

  context 'with a row spacing of zero' do
    let(:details) { { row_spacing: 0 } }

    it { is_expected.not_to be_valid }
  end

  context 'with a row spacing that is not a whole number' do
    let(:details) { { row_spacing: 12.5 } }

    it { is_expected.not_to be_valid }
  end

  context 'with a variety' do
    let(:details) { { variety: 'Island Bay Italian' } }

    it { is_expected.to be_valid }
  end

  context 'with a variety that is far too long' do
    let(:details) { { variety: 'a' * 101 } }

    it { is_expected.not_to be_valid }
  end

  context 'with the text read from a packet' do
    let(:details) { { packet_text: "Approx 15 seeds per packet\nSow by: December 2026" } }

    it { is_expected.to be_valid }
  end

  context 'with packet text that is far too long' do
    let(:details) { { packet_text: 'a' * 20_001 } }

    it { is_expected.not_to be_valid }
  end

  context 'with a batch number that is far too long' do
    let(:details) { { batch_number: 'a' * 101 } }

    it { is_expected.not_to be_valid }
  end
end
