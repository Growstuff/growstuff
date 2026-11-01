# frozen_string_literal: true

require 'rails_helper'

describe StallSeed do
  subject(:stall_seed) { build(:stall_seed) }

  it { is_expected.to be_valid }

  context 'with a seed from another member' do
    subject(:stall_seed) { build(:stall_seed, seed: create(:seed)) }

    it { is_expected.not_to be_valid }
  end

  context 'with a seed already on the stall' do
    subject(:again) { build(:stall_seed, stall: stall_seed.stall, seed: stall_seed.seed) }

    before { stall_seed.save! }

    it { is_expected.not_to be_valid }
  end
end
