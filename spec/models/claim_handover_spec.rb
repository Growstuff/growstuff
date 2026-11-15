# frozen_string_literal: true

require 'rails_helper'

# Handing something over takes both people: the claimer says they collected it, the giver says they handed it over, in either
# order. Then the original stays with the giver, given away, and a new record is made for the claimer.
describe Claim, 'handover' do
  let(:claimer) { create(:member) }
  let(:garden) { claimer.gardens.first }

  context 'with a packet of seed' do
    subject(:claim) { create(:claim, member: claimer) }

    let(:seed) { claim.stall_seed.seed }
    let(:giver) { seed.owner }

    context 'when the giver says so first' do
      before { claim.give }

      it 'takes the packet out of their library' do
        expect(seed.reload).to be_given_away
      end

      it 'has not made the claimer a packet yet' do
        expect(seed.reload.passed_on_as).to be_nil
      end

      it 'is not complete' do
        expect(claim).not_to be_completed
      end

      context 'when the claimer then says they collected it' do
        before { claim.receive }

        it 'makes the claimer a packet' do
          expect(seed.reload.passed_on_as.owner).to eq claimer
        end

        it 'knows where it came from' do
          expect(seed.reload.passed_on_as.received_from).to eq seed
        end

        it 'is complete' do
          expect(claim.reload).to be_completed
        end

        it 'leaves the original with the giver' do
          expect(seed.reload.owner).to eq giver
        end

        it 'starts the new packet out not for trading' do
          expect(seed.reload.passed_on_as.tradable_to).to eq 'nowhere'
        end
      end
    end

    context 'when the claimer says so first' do
      before { claim.receive }

      it 'leaves the packet in the giver\'s library' do
        expect(seed.reload).not_to be_given_away
      end

      it 'has not made the claimer a packet yet' do
        expect(seed.reload.passed_on_as).to be_nil
      end

      context 'when the giver then confirms' do
        before { claim.give }

        it 'makes the claimer a packet' do
          expect(seed.reload.passed_on_as.owner).to eq claimer
        end

        it 'takes the original out of the giver\'s library' do
          expect(seed.reload).to be_given_away
        end

        it 'is complete' do
          expect(claim.reload).to be_completed
        end
      end
    end

    context 'when it is already complete' do
      before do
        claim.give
        claim.receive
      end

      it 'cannot be handed over again' do
        expect(claim.give).to be false
      end
    end

    it 'cannot be given back once the giver has handed it over' do
      claim.give
      expect(claim).not_to be_undoable
    end
  end

  context 'with a seedling' do
    subject(:claim) { create(:claim, :for_seedling, member: claimer) }

    let(:offer) { claim.stall_planting }
    let(:original) { offer.planting }

    context 'when the giver says so first' do
      before { claim.give }

      it 'takes the seedling out of their active plantings' do
        expect(Planting.active).not_to include(original)
      end

      it 'is waiting for the claimer to accept' do
        expect(StallPlanting.waiting_for(claimer)).to eq [offer]
      end

      context 'when the claimer then says they collected it' do
        before { claim.reload.receive(garden) }

        it 'makes the claimer a planting in their garden' do
          expect(original.reload.passed_on_as).to have_attributes(owner: claimer, garden:)
        end

        it 'knows where it came from' do
          expect(original.reload.passed_on_as.received_from).to eq original
        end

        it 'is complete' do
          expect(claim.reload).to be_completed
        end
      end
    end

    context 'when the claimer says so first' do
      before { claim.receive(garden) }

      it 'leaves the seedling with the giver' do
        expect(Planting.active).to include(original)
      end

      it 'needs a garden of their own' do
        expect(create(:claim, :for_seedling, member: claimer).receive(create(:garden))).to be false
      end

      context 'when the giver then confirms' do
        before { claim.reload.give }

        it 'makes the claimer a planting in the garden they chose' do
          expect(original.reload.passed_on_as).to have_attributes(owner: claimer, garden:)
        end

        it 'takes the original out of the giver\'s active plantings' do
          expect(Planting.active).not_to include(original)
        end

        it 'is complete' do
          expect(claim.reload).to be_completed
        end
      end
    end
  end
end
