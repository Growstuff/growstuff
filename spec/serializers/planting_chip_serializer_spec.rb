# frozen_string_literal: true

require 'rails_helper'

describe PlantingChipSerializer do
  subject(:json) { described_class.new(planting, ability: Ability.new(nil)).as_json }

  let(:planting) { create(:planting, parent_seed: seed) }

  context 'when its parent seed has a variety' do
    let(:seed) { create(:seed, variety: 'Brandywine') }

    it 'includes the variety' do
      expect(json[:variety]).to eq 'Brandywine'
    end
  end

  context 'without a parent seed' do
    let(:seed) { nil }

    it 'has no variety' do
      expect(json[:variety]).to be_nil
    end
  end
end
