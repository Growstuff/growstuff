# frozen_string_literal: true

require 'rails_helper'

describe Claim do
  subject(:claim) { build(:claim) }

  it { is_expected.to be_valid }

  context 'when the stall owner claims their own packet' do
    subject(:claim) { build(:claim, member: stall_seed.stall.member, stall_seed:) }

    let(:stall_seed) { create(:stall_seed) }

    it { is_expected.not_to be_valid }
  end

  context 'when the packet is already claimed' do
    subject(:second) { build(:claim, stall_seed: claim.stall_seed) }

    before { claim.save! }

    it { is_expected.not_to be_valid }
  end

  context 'when the stall is closed' do
    before { claim.stall_seed.stall.close! }

    it { is_expected.not_to be_valid }
  end

  context 'with a very long note' do
    subject(:claim) { build(:claim, note: 'x' * 501) }

    it { is_expected.not_to be_valid }
  end

  context 'when the stall is for people nearby' do
    subject(:claim) { build(:claim, stall_seed:, member: friend, here:) }

    let(:owner) { create_located_member('Wellington, Wellington Region, New Zealand', -41.29, 174.78) }
    let(:stall_seed) { create(:stall_seed, stall: create(:stall, :open, member: owner, claim_area: 'region')) }
    let(:here) { nil }

    context 'when the friend lives far away' do
      let(:friend) { create_located_member('Auckland, Auckland, New Zealand', -36.85, 174.76) }

      it { is_expected.not_to be_valid }
    end

    context 'when the friend lives nearby' do
      let(:friend) { create_located_member('Lower Hutt, Wellington Region, New Zealand', -41.21, 174.9) }

      it { is_expected.to be_valid }
    end

    context 'when the friend has not said where they are' do
      let(:friend) { create(:member, location: nil, latitude: nil, longitude: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when the friend has not said where they are but says they are here' do
      let(:friend) { create(:member, location: nil, latitude: nil, longitude: nil) }
      let(:here) { '1' }

      it { is_expected.to be_valid }
    end
  end

  context 'when for an offered seedling' do
    subject(:claim) { build(:claim, :for_seedling) }

    it { is_expected.to be_valid }
  end

  context 'when for a seedling and a packet' do
    subject(:claim) { build(:claim, stall_planting: create(:stall_planting, :offered)) }

    it { is_expected.not_to be_valid }
  end

  context 'when for neither' do
    subject(:claim) { build(:claim, stall_seed: nil) }

    it { is_expected.not_to be_valid }
  end

  context 'when the seedling has been given to someone' do
    subject(:claim) { build(:claim, stall_seed: nil, stall_planting: create(:stall_planting)) }

    it { is_expected.not_to be_valid }
  end

  context 'when the seedling is already claimed' do
    subject(:second) { build(:claim, stall_seed: nil, stall_planting: claim.stall_planting) }

    let(:claim) { create(:claim, :for_seedling) }

    it { is_expected.not_to be_valid }
  end

  context 'when the stall owner claims their own seedling' do
    subject(:claim) { build(:claim, :for_seedling, member: offer.stall.member, stall_planting: offer) }

    let(:offer) { create(:stall_planting, :offered) }

    it { is_expected.not_to be_valid }
  end
end
