# frozen_string_literal: true

require 'rails_helper'

describe 'Claiming a seedling on offer', flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:stall) { create(:stall, :open, member: owner, claim_area: 'anywhere') }
  let!(:offer) { stall.offer_seedlings!([create(:planting, owner:, quantity: 3)]).first }

  context 'when a friend is signed in' do
    include_context 'signed in member'

    before do
      visit member_stall_path(owner)
      find('details.stall-claim summary').click
      click_button 'Claim it'
      find('.stall-ribbon') # claimed, so the server has finished
    end

    it 'claims it for them' do
      expect(offer.reload.claim.member).to eq member
    end
  end

  context 'when the owner gives it to the friend who claimed it' do
    let(:friend) { create(:member) }

    before do
      create(:claim, member: friend, stall_seed: nil, stall_planting: offer)
      sign_in owner
      visit member_stall_path(owner)
      # Buttons are shown in capitals, which click_button's text match doesn't allow for.
      find('button', text: /i gave it to #{friend}/i).click # rubocop:disable Capybara/SpecificActions
      find_by_id('stall-given-h') # given, so the server has finished
    end

    it 'leaves it waiting for the friend to add to a garden' do
      expect(StallPlanting.waiting_for(friend)).to eq [offer]
    end
  end
end
