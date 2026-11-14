# frozen_string_literal: true

require 'rails_helper'

describe Stalls::PlantingsController, flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:nursery) { owner.nursery! }
  let!(:seedling) { create(:planting, owner:, garden: nursery, crop: create(:crop, name: 'kale')) }
  let!(:garden_planting) { create(:planting, owner:, garden: create(:garden, owner:)) }
  let(:params) { { planting_ids: [seedling.id], recipient_kind: 'email', recipient: 'neighbour@example.com', given_on: '2026-11-14' } }

  before { sign_in owner }

  describe 'GET /stall/plantings/new' do
    before { get new_stall_planting_path(status: 'given') }

    it 'lists the seedlings to give' do
      expect(Capybara.string(response.body)).to have_field("planting_ids_#{seedling.id}")
    end

    it 'leaves out plantings that are not in the nursery' do
      expect(Capybara.string(response.body)).to have_no_field("planting_ids_#{garden_planting.id}")
    end

    it 'asks who has them, once given' do
      expect(Capybara.string(response.body)).to have_field('recipient')
    end

    context 'when putting them on the stall' do
      before { get new_stall_planting_path(status: 'offered') }

      it 'does not ask who has them' do
        expect(Capybara.string(response.body)).to have_no_field('recipient')
      end

      it 'does not ask when' do
        expect(Capybara.string(response.body)).to have_no_field('given_on')
      end
    end
  end

  describe 'POST /stall/plantings' do
    context 'with a seedling and an email address' do
      before { post stall_plantings_path, params: }

      it 'goes back to the stall' do
        expect(response).to redirect_to(member_stall_path(owner))
      end

      it 'records it as given away' do
        expect(owner.stall.stall_plantings.first).to have_attributes(planting: seedling, recipient: 'neighbour@example.com')
      end

      it 'takes it out of their active plantings' do
        expect(owner.plantings.active).not_to include(seedling)
      end
    end

    context 'when putting them on the stall with nobody to give them to yet' do
      before { post stall_plantings_path, params: { planting_ids: [seedling.id], status: 'offered' } }

      it 'puts the seedling on offer' do
        expect(owner.stall.seedlings_on_offer.map(&:planting)).to eq [seedling]
      end

      it 'leaves it an active planting' do
        expect(owner.plantings.active).to include(seedling)
      end
    end

    context 'with a recipient that is not an address' do
      before { post stall_plantings_path, params: params.merge(recipient: 'nobody') }

      it { expect(response).to have_http_status(:unprocessable_content) }

      it 'gives nothing away' do
        expect(seedling.reload).not_to be_given_away
      end
    end

    context 'without choosing a seedling' do
      before { post stall_plantings_path, params: params.merge(planting_ids: []) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path)
      end
    end

    context 'with a planting that is not in the nursery' do
      before { post stall_plantings_path, params: params.merge(planting_ids: [garden_planting.id]) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path)
      end
    end

    context "with someone else's planting" do
      before { post stall_plantings_path, params: params.merge(planting_ids: [create(:planting).id]) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path)
      end
    end
  end

  describe 'DELETE /stall/plantings/:id' do
    let!(:offer) { owner.stall!.offer_seedlings!([seedling]).first }

    it 'takes an offered seedling off the stall' do
      delete stall_planting_path(offer)
      expect(owner.stall.stall_plantings.reload).to be_empty
    end

    it 'keeps one that was given' do
      owner.stall.give_away!([seedling], kind: 'email', recipient: 'a@example.com')
      delete stall_planting_path(offer)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when signed out' do
    before do
      sign_out owner
      get new_stall_planting_path
    end

    it 'asks them to sign in' do
      expect(response).to redirect_to(new_member_session_path)
    end
  end
end
