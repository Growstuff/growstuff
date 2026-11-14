# frozen_string_literal: true

require 'rails_helper'

describe PlantingChipSerializer do
  subject(:json) { described_class.new(planting, ability: Ability.new(nil)).as_json }

  let(:planting) { create(:planting, parent_seed: seed) }

  context 'when its parent seed has a variety' do
    let(:seed) { create(:seed, variety: 'Brandywine') }

    it 'labels the chip with the crop and the variety in brackets' do
      expect(json[:label]).to eq "#{planting.crop.name} (Brandywine)"
    end
  end

  context 'without a parent seed' do
    let(:seed) { nil }

    it 'labels the chip with the crop' do
      expect(json[:label]).to eq planting.crop.name
    end
  end
end
