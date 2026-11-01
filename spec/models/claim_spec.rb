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
end
