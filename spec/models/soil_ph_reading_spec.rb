# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SoilPhReading do
  subject(:reading) { described_class.new(garden: build(:garden), measured_on: Date.new(2026, 11, 1), ph: ph) }

  [0, 6.75, 7, 14].each do |value|
    context "with a pH of #{value}" do
      let(:ph) { value }

      it 'accepts the reading' do
        expect(reading).to be_valid
      end
    end
  end

  [nil, -0.01, 14.01, 'not a number'].each do |value|
    context "with an invalid pH of #{value.inspect}" do
      let(:ph) { value }

      it 'rejects the reading' do
        expect(reading).not_to be_valid
      end
    end
  end

  context 'without a measurement date' do
    let(:ph) { 7 }

    it 'rejects the reading' do
      reading.measured_on = nil
      expect(reading).not_to be_valid
    end
  end
end
