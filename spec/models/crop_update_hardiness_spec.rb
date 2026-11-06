# frozen_string_literal: true

require 'rails_helper'

describe Crop, '#update_hardiness' do
  subject(:crop) { create(:crop) }

  let(:member) { create(:member) }

  def name_crop(crop, name)
    crop.scientific_names.create!(name:, creator: member)
  end

  context 'with no packets and no EcoCrop record' do
    before { crop.update_hardiness }

    it 'is unknown' do
      expect(crop.reload.hardiness).to eq 'unknown'
    end

    it 'has no source' do
      expect(crop.reload.hardiness_source).to be_nil
    end
  end

  context 'with an EcoCrop killing temperature' do
    before do
      name_crop(crop, 'Brassica oleracea')
      create(:ecocrop_data, scientificname: 'Brassica oleracea', ktmp: -8)
      crop.update_hardiness
    end

    it 'takes the level from the temperature' do
      expect(crop.reload.hardiness).to eq 'hardy'
    end

    it 'names EcoCrop as the source' do
      expect(crop.reload.hardiness_source).to eq 'ecocrop'
    end

    it 'keeps the temperature' do
      expect(crop.reload.lowest_tolerated_c).to eq(-8)
    end
  end

  context 'with a variety of a crop that has an EcoCrop temperature' do
    let(:variety) { create(:crop, parent: crop) }

    before do
      name_crop(crop, 'Solanum lycopersicum')
      create(:ecocrop_data, scientificname: 'Solanum lycopersicum', ktmp: 1)
      variety.update_hardiness
    end

    it 'follows the parent' do
      expect(variety.reload.hardiness).to eq 'tender'
    end
  end

  context 'with an EcoCrop record without a killing temperature' do
    before do
      name_crop(crop, 'Solanum lycopersicum')
      create(:ecocrop_data, scientificname: 'Solanum lycopersicum', ktmp: nil)
      crop.update_hardiness
    end

    it 'is unknown' do
      expect(crop.reload.hardiness).to eq 'unknown'
    end
  end

  context 'with packets that disagree with EcoCrop' do
    before do
      name_crop(crop, 'Brassica oleracea')
      create(:ecocrop_data, scientificname: 'Brassica oleracea', ktmp: -8)
      create_list(:seed, 2, crop:, hardiness: 'half_hardy')
      create(:seed, crop:, hardiness: 'hardy')
      crop.update_hardiness
    end

    it 'goes with the packets' do
      expect(crop.reload.hardiness).to eq 'half_hardy'
    end

    it 'names the packets as the source' do
      expect(crop.reload.hardiness_source).to eq 'seed_packets'
    end

    it 'still keeps the EcoCrop temperature' do
      expect(crop.reload.lowest_tolerated_c).to eq(-8)
    end
  end

  context 'when a packet is saved' do
    before { create(:seed, crop:, hardiness: 'tender') }

    it 'updates the crop' do
      expect(crop.reload.hardiness).to eq 'tender'
    end
  end

  context 'with a value set by hand' do
    before do
      crop.update_columns(hardiness: 'hardy', hardiness_source: 'manual') # rubocop:disable Rails/SkipsModelValidations
      create(:seed, crop:, hardiness: 'tender')
      crop.update_hardiness
    end

    it 'keeps it' do
      expect(crop.reload.hardiness).to eq 'hardy'
    end
  end

  describe '.update_all_hardiness' do
    before do
      name_crop(crop, 'Brassica oleracea')
      create(:ecocrop_data, scientificname: 'Brassica oleracea', ktmp: -8)
      described_class.update_all_hardiness
    end

    it 'works out every crop' do
      expect(crop.reload.hardiness).to eq 'hardy'
    end
  end
end
