# frozen_string_literal: true

require 'rails_helper'

describe Hardiness do
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
