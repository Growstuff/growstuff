# frozen_string_literal: true

require 'rails_helper'

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
