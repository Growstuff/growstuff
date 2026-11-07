# frozen_string_literal: true

require 'rails_helper'

describe Member do
  subject(:member) { build(:member, label_width_mm: width, label_height_mm: height) }

  let(:width) { '62' }
  let(:height) { '29' }

  it 'accepts a label size' do
    expect(member).to be_valid
  end

  context 'without a preference' do
    let(:width) { '' }
    let(:height) { '' }

    it 'accepts blank dimensions' do
      expect(member).to be_valid
    end
  end

  context 'with decimal dimensions' do
    let(:width) { '50.5' }

    it 'accepts millimetre fractions' do
      expect(member).to be_valid
    end
  end

  context 'without a height' do
    let(:height) { '' }

    it 'requires both dimensions' do
      expect(member).not_to be_valid
    end
  end

  context 'without a width' do
    let(:width) { '' }

    it 'requires both dimensions' do
      expect(member).not_to be_valid
    end
  end

  context 'with an invalid dimension' do
    ['abc', 'NaN', 'Infinity', '19.9', '300.1', '-1'].each do |value|
      context "when the width is #{value}" do
        let(:width) { value }

        it 'rejects the preference' do
          expect(member).not_to be_valid
        end
      end
    end
  end
end
