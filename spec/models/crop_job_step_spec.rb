# frozen_string_literal: true

require 'rails_helper'

describe CropJobStep do
  subject(:step) { build(:crop_job_step) }

  it { is_expected.to be_valid }

  it 'needs a name' do
    step.name = nil
    expect(step).not_to be_valid
  end

  it 'rejects a negative offset' do
    step.offset_amount = -1
    expect(step).not_to be_valid
  end

  it 'rejects an unknown anchor' do
    step.anchor = 'full_moon'
    expect(step).not_to be_valid
  end

  describe 'external_uri' do
    it 'is optional' do
      step.external_uri = nil
      expect(step).to be_valid
    end

    it 'can be a web address' do
      step.external_uri = 'https://example.com/staking-tomatoes'
      expect(step).to be_valid
    end

    it 'treats an empty one as none' do
      step.external_uri = ''
      expect(step).to be_valid
    end

    it 'must start with http:// or https://' do
      step.external_uri = 'ftp://example.com/guide'
      expect(step).not_to be_valid
    end

    it 'says what is wrong' do
      step.external_uri = 'example.com'
      step.valid?
      expect(step.errors[:external_uri]).to eq ['must start with http:// or https://']
    end
  end

  it 'happens once by default' do
    expect(step).to be_repeat_once
  end

  describe '#offset' do
    subject(:offset) { step.offset }

    let(:step) { build(:crop_job_step, offset_amount: 2, offset_unit: 'weeks', direction: direction) }

    context 'when after its anchor' do
      let(:direction) { 'after' }

      it { is_expected.to eq 2.weeks }
    end

    context 'when before its anchor' do
      let(:direction) { 'before' }

      it { is_expected.to eq(-2.weeks) }
    end
  end
end
