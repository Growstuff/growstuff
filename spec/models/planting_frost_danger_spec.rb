# frozen_string_literal: true

require 'rails_helper'

describe Planting, '#frost_danger' do
  subject(:planting) { create(:planting, garden:, owner: garden.owner) }

  let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations

  context 'when the cell has frost dates' do
    let!(:stat) { create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_DANGER_C) }

    it 'finds them' do
      expect(planting.frost_danger).to eq stat
    end
  end

  context 'when only the 0 degree dates are there' do
    before { create(:frost_stat, latitude: -41.25, longitude: 174.75, threshold_c: FrostCalculator::FROST_C) }

    it 'is nil' do
      expect(planting.frost_danger).to be_nil
    end
  end

  context 'when another cell has them' do
    before { create(:frost_stat, latitude: 10.0, longitude: 10.0, threshold_c: FrostCalculator::FROST_DANGER_C) }

    it 'is nil' do
      expect(planting.frost_danger).to be_nil
    end
  end

  context 'when the garden has no location' do
    let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations

    it 'is nil' do
      expect(planting.frost_danger).to be_nil
    end
  end
end
