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

    it 'does not put a packet on twice' do
      expect { stall.put_seeds_on!([shared_seed]) }.not_to change(stall.stall_seeds, :count)
    end
  end
end
