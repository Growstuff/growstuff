# frozen_string_literal: true

require 'rails_helper'

describe Hardiness do
  describe '.from_lowest_c' do
    it 'is unknown without a temperature' do
      expect(described_class.from_lowest_c(nil)).to eq 'unknown'
    end

    it 'is tender when it is killed at 2 degrees' do
      expect(described_class.from_lowest_c(2)).to eq 'tender'
    end

    it 'is tender when it is killed just below freezing' do
      expect(described_class.from_lowest_c(-0.5)).to eq 'tender'
    end

    it 'is half-hardy when it takes a light frost' do
      expect(described_class.from_lowest_c(-3)).to eq 'half_hardy'
    end

    it 'is half-hardy at the hardy boundary' do
      expect(described_class.from_lowest_c(-5)).to eq 'half_hardy'
    end

    it 'is hardy when it takes a hard frost' do
      expect(described_class.from_lowest_c(-12)).to eq 'hardy'
    end
  end

  describe '.most_common' do
    it 'is unknown when none is given' do
      expect(described_class.most_common({})).to eq 'unknown'
    end

    it 'ignores unknown' do
      expect(described_class.most_common('unknown' => 5, 'hardy' => 1)).to eq 'hardy'
    end

    it 'picks the one given most often' do
      expect(described_class.most_common('tender' => 1, 'hardy' => 3)).to eq 'hardy'
    end

    it 'gives a tie to the more tender' do
      expect(described_class.most_common('tender' => 2, 'hardy' => 2)).to eq 'tender'
    end
  end
end
