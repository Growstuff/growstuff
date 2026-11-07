# frozen_string_literal: true

require 'rails_helper'

describe Planting, '#hardiness_found' do
  subject(:found) { planting.hardiness_found }

  let(:planting) { build(:planting, hardiness:, parent_seed: seed, crop:) }
  let(:hardiness) { 'unknown' }
  let(:seed) { build(:seed, hardiness: 'half_hardy') }
  let(:crop) { build(:crop, hardiness: 'hardy') }

  context 'with a level of its own' do
    let(:hardiness) { 'tender' }

    it { is_expected.to eq [:planting, 'tender'] }
  end

  context 'without a level of its own' do
    it { is_expected.to eq [:seed, 'half_hardy'] }
  end

  context 'with a seed that does not know' do
    let(:seed) { build(:seed, hardiness: 'unknown') }

    it { is_expected.to eq [:crop, 'hardy'] }
  end

  context 'without a seed' do
    let(:seed) { nil }

    it { is_expected.to eq [:crop, 'hardy'] }
  end

  context 'when nobody knows' do
    let(:seed) { nil }
    let(:crop) { build(:crop, hardiness: 'unknown') }

    it { is_expected.to be_nil }
  end
end
