# frozen_string_literal: true

require 'rails_helper'

describe SeedCropChange do
  subject(:change) { described_class.new(seed, old_crop) }

  let(:owner) { create(:member) }
  let(:old_crop) { create(:crop) }
  let(:new_crop) { create(:crop) }
  let(:seed) { create(:seed, owner:, crop: new_crop) }
  let!(:planting) { create(:planting, owner:, crop: old_crop, parent_seed: seed) }
  let!(:harvest) { create(:harvest, planting:, owner:) }
  let!(:saved_seed) { create(:seed, owner:, crop: old_crop, parent_planting: planting) }

  it { expect(change.plantings).to eq [planting] }
  it { expect(change.harvests).to eq [harvest] }
  it { expect(change.seeds).to eq [saved_seed] }

  context 'when the crop is unchanged' do
    subject(:change) { described_class.new(seed, new_crop) }

    it { is_expected.not_to be_any }
  end

  context 'with a planting of another member' do
    let!(:others) { create(:planting, crop: old_crop, parent_seed: seed) }

    it { expect(change.plantings).not_to include(others) }
  end

  context 'with a planting of another crop' do
    let!(:other_crop_planting) { create(:planting, owner:, parent_seed: seed) }

    it { expect(change.plantings).not_to include(other_crop_planting) }
  end

  describe '#apply!' do
    before { change.apply! }

    it { expect(planting.reload.crop).to eq new_crop }
    it { expect(harvest.reload.crop).to eq new_crop }
    it { expect(saved_seed.reload.crop).to eq new_crop }
  end
end
