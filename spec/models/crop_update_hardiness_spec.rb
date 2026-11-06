# frozen_string_literal: true

require 'rails_helper'

describe Crop, '#update_hardiness' do
  subject(:crop) { create(:crop) }

  context 'with no packets' do
    before { crop.update_hardiness }

    it 'is unknown' do
      expect(crop.reload.hardiness).to eq 'unknown'
    end

    it 'has no source' do
      expect(crop.reload.hardiness_source).to be_nil
    end
  end

  context 'with packets that disagree' do
    before do
      create_list(:seed, 2, crop:, hardiness: 'half_hardy')
      create(:seed, crop:, hardiness: 'hardy')
      create(:seed, crop:, hardiness: 'unknown')
    end

    it 'goes with the most common' do
      expect(crop.reload.hardiness).to eq 'half_hardy'
    end

    it 'names the packets as the source' do
      expect(crop.reload.hardiness_source).to eq 'seed_packets'
    end
  end

  context 'with a packet of a variety' do
    before { create(:seed, crop: create(:crop, parent: crop), hardiness: 'tender') }

    it 'counts for the parent crop' do
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

  context 'when the only packet changes to unknown' do
    let!(:seed) { create(:seed, crop:, hardiness: 'tender') }

    before { seed.update!(hardiness: 'unknown') }

    it 'goes back to unknown' do
      expect(crop.reload.hardiness).to eq 'unknown'
    end
  end

  describe '.update_all_hardiness' do
    before do
      create(:seed, crop:, hardiness: 'hardy')
      crop.update_columns(hardiness: 'unknown', hardiness_source: nil) # rubocop:disable Rails/SkipsModelValidations
      described_class.update_all_hardiness
    end

    it 'works out every crop' do
      expect(crop.reload.hardiness).to eq 'hardy'
    end
  end
end

describe Crop, '#hardiness_by_hand=' do
  subject(:crop) { create(:crop) }

  context 'with a level' do
    before { crop.update!(hardiness_by_hand: 'tender') }

    it 'sets it' do
      expect(crop.reload.hardiness).to eq 'tender'
    end

    it 'names a wrangler as the source' do
      expect(crop.reload.hardiness_source).to eq 'manual'
    end

    it 'is not overwritten by packets' do
      create(:seed, crop:, hardiness: 'hardy')
      expect(crop.reload.hardiness).to eq 'tender'
    end

    it 'reads back as the level' do
      expect(crop.reload.hardiness_by_hand).to eq 'tender'
    end
  end

  context 'with a bad level' do
    it 'is not valid' do
      crop.hardiness_by_hand = 'very'
      expect(crop).not_to be_valid
    end
  end

  context 'with blank after a level was set' do
    before do
      create(:seed, crop:, hardiness: 'hardy')
      crop.update!(hardiness_by_hand: 'tender')
      crop.update!(hardiness_by_hand: '')
    end

    it 'hands it back to the packets' do
      expect(crop.reload.hardiness).to eq 'hardy'
    end

    it 'names the packets as the source' do
      expect(crop.reload.hardiness_source).to eq 'seed_packets'
    end

    it 'reads back as blank' do
      expect(crop.reload.hardiness_by_hand).to be_blank
    end
  end

  context 'with blank when nothing was set by hand' do
    before do
      create(:seed, crop:, hardiness: 'hardy')
      crop.update!(hardiness_by_hand: '')
    end

    it 'leaves the packets in charge' do
      expect(crop.reload.hardiness_source).to eq 'seed_packets'
    end
  end
end
