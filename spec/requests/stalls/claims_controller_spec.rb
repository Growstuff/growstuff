# frozen_string_literal: true

require 'rails_helper'

describe Stalls::ClaimsController, flipper: :garden_stall do
  let(:stall_seed) { create(:stall_seed) }
  let(:owner) { stall_seed.stall.member }
  let(:friend) { create_located_member('Sydney, New South Wales, Australia', -33.87, 151.2) }

  describe 'POST /stall_seeds/:id/claim' do
    context 'when signed in as a friend' do
      before do
        sign_in friend
        post stall_seed_claim_path(stall_seed), params: { note: 'For my balcony' }
      end

      it 'claims the packet' do
        expect(stall_seed.reload.claim.member).to eq(friend)
      end

      it 'keeps their note' do
        expect(stall_seed.reload.claim.note).to eq('For my balcony')
      end

      it 'goes back to the stall' do
        expect(response).to redirect_to(member_stall_path(owner))
      end
    end

    context 'when the stall is for people nearby and the friend is far away' do
      let(:stall_seed) do
        owner = create_located_member('Wellington, Wellington Region, New Zealand', -41.29, 174.78)
        create(:stall_seed, stall: create(:stall, :open, member: owner, claim_area: 'region'))
      end

      before do
        sign_in friend
        post stall_seed_claim_path(stall_seed)
      end

      it 'does not claim it' do
        expect(stall_seed.reload.claim).to be_nil
      end

      it 'says the stall is for people near Wellington' do
        expect(flash.alert).to include('only for people near Wellington')
      end
    end

    context 'when someone has already claimed it' do
      before do
        create(:claim, stall_seed:)
        sign_in friend
        post stall_seed_claim_path(stall_seed)
      end

      it 'leaves the first claim' do
        expect(stall_seed.reload.claim.member).not_to eq(friend)
      end
    end

    context 'when signed in as the owner' do
      before do
        sign_in owner
        post stall_seed_claim_path(stall_seed)
      end

      it 'does not claim it' do
        expect(stall_seed.reload.claim).to be_nil
      end
    end

    context 'when signed out' do
      before { post stall_seed_claim_path(stall_seed) }

      it 'asks them to sign in' do
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end

  describe 'DELETE /stall_seeds/:id/claim' do
    context 'when it is their own claim' do
      before do
        create(:claim, stall_seed:, member: friend)
        sign_in friend
        delete stall_seed_claim_path(stall_seed)
      end

      it 'gives the packet back' do
        expect(stall_seed.reload.claim).to be_nil
      end
    end

    context 'when it is someone else\'s claim' do
      before do
        create(:claim, stall_seed:)
        sign_in friend
        delete stall_seed_claim_path(stall_seed)
      end

      it 'leaves it alone' do
        expect(stall_seed.reload.claim).to be_present
      end
    end
  end

  describe 'for an offered seedling' do
    let(:offer) { create(:stall_planting, :offered) }

    context 'when signed in as a friend' do
      before do
        sign_in friend
        post stall_planting_claim_path(offer), params: { note: 'For my balcony' }
      end

      it 'claims the seedling' do
        expect(offer.reload.claim.member).to eq(friend)
      end

      it 'goes back to the stall' do
        expect(response).to redirect_to(member_stall_path(offer.stall.member))
      end
    end

    context 'when giving it back' do
      before do
        create(:claim, member: friend, stall_seed: nil, stall_planting: offer)
        sign_in friend
        delete stall_planting_claim_path(offer)
      end

      it 'is no longer claimed' do
        expect(offer.reload.claim).to be_nil
      end
    end

    context 'when signed out' do
      it 'asks them to sign in' do
        post stall_planting_claim_path(offer)
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end

  describe 'handing a packet over' do
    let(:claim) { create(:claim, stall_seed:, member: friend) }

    context 'when the claimer says they collected it' do
      before do
        claim
        sign_in friend
        post received_stall_seed_claim_path(stall_seed)
      end

      it 'records it' do
        expect(claim.reload).to be_received
      end

      it 'is not theirs until the giver confirms' do
        expect(stall_seed.seed.reload.passed_on_as).to be_nil
      end
    end

    context 'when the giver confirms they handed it over' do
      before do
        claim.receive
        sign_in owner
        post given_stall_seed_claim_path(stall_seed)
      end

      it 'makes the claimer a packet' do
        expect(stall_seed.seed.reload.passed_on_as.owner).to eq friend
      end
    end

    context 'when someone else tries to say it was handed over' do
      before do
        claim
        sign_in create(:member)
        post given_stall_seed_claim_path(stall_seed)
      end

      it 'is not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when giving it back after it was handed over' do
      before do
        claim.give
        sign_in friend
        delete stall_seed_claim_path(stall_seed)
      end

      it 'keeps the claim' do
        expect(claim.reload).to be_persisted
      end
    end
  end

  describe 'handing a seedling over' do
    let(:offer) { create(:stall_planting, :offered) }
    let(:garden) { friend.gardens.first }

    context 'when the claimer says they collected it, into a garden' do
      before do
        create(:claim, member: friend, stall_seed: nil, stall_planting: offer)
        sign_in friend
        post received_stall_planting_claim_path(offer), params: { garden_id: garden.id }
      end

      it 'records the garden' do
        expect(offer.reload.claim.receiving_garden).to eq garden
      end
    end

    context 'when the claimer says they collected it without a garden' do
      before do
        create(:claim, member: friend, stall_seed: nil, stall_planting: offer)
        sign_in friend
        post received_stall_planting_claim_path(offer)
      end

      it 'does not record it' do
        expect(offer.reload.claim).not_to be_received
      end
    end

    context 'when the giver then confirms' do
      before do
        create(:claim, member: friend, stall_seed: nil, stall_planting: offer).receive(garden)
        sign_in offer.stall.member
        post given_stall_planting_claim_path(offer)
      end

      it 'makes the claimer a planting' do
        expect(offer.planting.reload.passed_on_as).to have_attributes(owner: friend, garden:)
      end
    end
  end
end
