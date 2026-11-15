# frozen_string_literal: true

require 'rails_helper'

describe StallHandovers do
  subject(:handovers) { described_class.new(member) }

  let(:member) { create(:member) }

  describe '#to_receive_count' do
    it 'counts seedlings given to them' do
      create(:stall_planting, recipient_member: member)
      expect(handovers.to_receive_count).to eq 1
    end

    it 'counts packets the giver says they handed over' do
      create(:claim, member:).give
      expect(handovers.to_receive_count).to eq 1
    end

    it 'does not count packets the giver has not said they handed over' do
      create(:claim, member:)
      expect(handovers.to_receive_count).to eq 0
    end

    it 'does not count what is already theirs' do
      claim = create(:claim, member:)
      claim.give
      claim.receive
      expect(handovers.to_receive_count).to eq 0
    end
  end

  describe '#to_give' do
    let(:claim) { create(:claim) }
    let(:giver) { claim.stall.member }

    it 'finds claims the claimer says they collected' do
      claim.receive
      expect(described_class.new(giver).to_give).to eq [claim]
    end

    it 'leaves out claims not collected yet' do
      claim
      expect(described_class.new(giver).to_give).to be_empty
    end

    it 'is empty for someone with no stall' do
      expect(handovers.to_give).to be_empty
    end
  end
end
