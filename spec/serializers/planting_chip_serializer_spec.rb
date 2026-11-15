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

  context 'when the member has their own name for the crop' do
    let(:seed) { nil }
    let(:planting) do
      crop = create(:crop, name: 'tomato')
      create(:planting, crop:, parent_seed: nil, alternate_name: create(:alternate_name, crop:, name: 'love apple'))
    end

    it 'labels the chip with their name, not the crop' do
      expect(json[:label]).to eq 'love apple'
    end

    it 'puts the variety in brackets after it' do
      planting.parent_seed = create(:seed, crop: planting.crop, variety: 'Brandywine')

      expect(json[:label]).to eq 'love apple (Brandywine)'
    end
  end
end
