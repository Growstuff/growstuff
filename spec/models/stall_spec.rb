# frozen_string_literal: true

require 'rails_helper'

describe Stall do
  subject(:stall) { create(:stall) }

  it { is_expected.not_to be_open }

  describe '#open!' do
    before { stall.open! }

    it { is_expected.to be_open }
  end

  describe '#close!' do
    subject(:stall) { create(:stall, :open) }

    before { stall.close! }

    it { is_expected.not_to be_open }
  end

  describe 'with a second stall for the same member' do
    subject(:second) { build(:stall, member: stall.member) }

    it { is_expected.not_to be_valid }
  end

  describe '#put_seeds_on!' do
    subject(:stall) { create(:stall, :open) }

    let(:private_seed) { create(:seed, owner: stall.member, tradable_to: 'nowhere') }
    let(:shared_seed) { create(:seed, owner: stall.member, tradable_to: 'nationally') }

    before { stall.put_seeds_on!([private_seed, shared_seed]) }

    it 'puts the packets on the stall' do
      expect(stall.seeds).to contain_exactly(private_seed, shared_seed)
    end

    it 'marks a packet as will trade' do
      expect(private_seed.reload.tradable_to).to eq('locally')
    end

    it 'leaves a packet that was already tradable alone' do
      expect(shared_seed.reload.tradable_to).to eq('nationally')
    end

    it 'offers them free by default' do
      expect(stall.stall_seeds.map(&:offer).uniq).to eq(['free'])
    end

    it 'does not put a packet on twice' do
      expect { stall.put_seeds_on!([shared_seed]) }.not_to change(stall.stall_seeds, :count)
    end
  end

  describe '#put_seeds_on! as a swap' do
    subject(:stall) { create(:stall, :open) }

    before { stall.put_seeds_on!([create(:seed, owner: stall.member)], offer: :swap) }

    it 'offers them as a swap' do
      expect(stall.stall_seeds.first).to be_swap
    end
  end

  describe '#area_check' do
    subject(:check) { stall.area_check(friend) }

    let(:wellington) { create_located_member('Wellington, Wellington Region, New Zealand', -41.29, 174.78) }
    let(:stall) { create(:stall, :open, member: wellington, claim_area:) }
    let(:claim_area) { 'region' }

    context 'when the friend lives nearby' do
      let(:friend) { create_located_member('Lower Hutt, Wellington Region, New Zealand', -41.21, 174.9) }

      it { is_expected.to eq(:ok) }
    end

    context 'when locations are written differently' do
      let(:wellington) { create_located_member('porirua, wellington', -41.13, 174.84) }
      let(:friend) { create_located_member('wellington, new zealand', -41.29, 174.78) }

      it { is_expected.to eq(:ok) }
    end

    context 'when the friend lives far away' do
      let(:friend) { create_located_member('Auckland, Auckland, New Zealand', -36.85, 174.76) }

      it { is_expected.to eq(:outside) }
    end

    context 'when the friend has not said where they are' do
      let(:friend) { create(:member, location: nil, latitude: nil, longitude: nil) }

      it { is_expected.to eq(:ask) }
    end

    context 'when the stall is open to anywhere' do
      let(:claim_area) { 'anywhere' }
      let(:friend) { create(:member, location: nil, latitude: nil, longitude: nil) }

      it { is_expected.to eq(:ok) }
    end

    context 'when the owner has not said where they are' do
      let(:stall) { create(:stall, :open, member: create(:member, location: nil, latitude: nil, longitude: nil)) }
      let(:friend) { wellington }

      it { is_expected.to eq(:owner_unplaced) }
    end
  end
end
