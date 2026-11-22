# frozen_string_literal: true

require 'rails_helper'

describe PlantingSeedling do
  subject(:seedling) { build(:planting_seedling, source:) }

  context 'with a known source' do
    let(:source) { 'nursery' }

    it { is_expected.to be_valid }
  end

  context 'without a source' do
    let(:source) { nil }

    it { is_expected.to be_valid }
  end

  context 'with an unknown source' do
    let(:source) { 'moon' }

    it { is_expected.not_to be_valid }
  end
end
