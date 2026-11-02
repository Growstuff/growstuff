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
end
