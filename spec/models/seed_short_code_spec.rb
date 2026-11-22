# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#short_code' do
  let(:owner) { create(:member) }
  let(:crop) { create(:crop, name: 'tomato') }

  describe 'when a packet is created' do
    subject(:code) { create(:seed, owner:, crop:).short_code }

    it { is_expected.to match(described_class::SHORT_CODE_FORMAT) }
    it { is_expected.to start_with 'T' }
  end

  describe 'a crop named with a letter that planting codes leave out' do
    let(:crop) { create(:crop, name: 'onion') }

    it 'still starts with the crop letter' do
      expect(create(:seed, owner:, crop:).short_code).to start_with 'O'
    end
  end

  describe 'a crop named with an accented letter' do
    let(:crop) { create(:crop, name: 'échalote') }

    it 'starts with the unaccented letter' do
      expect(create(:seed, owner:, crop:).short_code).to start_with 'E'
    end
  end

  describe 'a crop whose name has no letter' do
    let(:crop) { create(:crop, name: '123') }

    it 'is a valid code anyway' do
      expect(create(:seed, owner:, crop:).short_code).to match(described_class::SHORT_CODE_FORMAT)
    end
  end

  describe 'a packet saved before codes existed' do
    let(:seed) { create(:seed, owner:, crop:) }

    before { seed.update_column(:short_code, nil) } # rubocop:disable Rails/SkipsModelValidations

    it 'is valid without a code' do
      expect(seed.reload.valid?).to be true
    end

    it 'gets a code when next saved' do
      seed.update!(quantity: 5)
      expect(seed.reload.short_code).to be_present
    end

    it 'can be loaded and shown without a code' do
      expect(described_class.find(seed.id).short_code).to be_nil
    end
  end

  describe 'a code that is already set' do
    let(:seed) { create(:seed, owner:, crop:, short_code: 'T2B3') }

    it 'is kept when the packet is saved again' do
      seed.update!(quantity: 5)
      expect(seed.reload.short_code).to eq 'T2B3'
    end

    it 'is kept when the crop is changed' do
      seed.update!(crop: create(:crop, name: 'pea'))
      expect(seed.reload.short_code).to eq 'T2B3'
    end
  end

  describe 'validation' do
    it 'rejects a code of the wrong length' do
      expect(build(:seed, owner:, crop:, short_code: 'T2B')).not_to be_valid
    end

    it 'rejects a code that starts with a digit' do
      expect(build(:seed, owner:, crop:, short_code: '2ABC')).not_to be_valid
    end

    it 'rejects look-alike characters after the first' do
      expect(build(:seed, owner:, crop:, short_code: 'T0O1')).not_to be_valid
    end

    it 'rejects a code the owner already has on another packet' do
      create(:seed, owner:, crop:, short_code: 'T2B3')
      expect(build(:seed, owner:, crop:, short_code: 'T2B3')).not_to be_valid
    end

    it 'allows the same code on another member\'s packet' do
      create(:seed, owner:, crop:, short_code: 'T2B3')
      expect(build(:seed, owner: create(:member), crop:, short_code: 'T2B3')).to be_valid
    end
  end

  describe '.generate_short_code' do
    before { allow(described_class).to receive(:random_short_code).and_return('T234', 'T567') }

    it 'skips a code the owner has on a packet' do
      create(:seed, owner:, crop:, short_code: 'T234')
      expect(described_class.generate_short_code(owner:, crop:)).to eq 'T567'
    end

    it 'skips a code the owner has on a planting' do
      create(:planting, owner:, garden: create(:garden, owner:), crop:, short_code: 'T234')
      expect(described_class.generate_short_code(owner:, crop:)).to eq 'T567'
    end
  end
end
