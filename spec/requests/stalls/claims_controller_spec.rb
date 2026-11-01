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
end
