# frozen_string_literal: true

require 'rails_helper'

describe Stalls::PlantingsController, flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:nursery) { owner.nursery! }
  let!(:seedling) { create(:planting, owner:, garden: nursery, crop: create(:crop, name: 'kale'), quantity: 6) }
  let!(:garden_planting) { create(:planting, owner:, garden: create(:garden, owner:)) }
  let(:neighbour) { create(:member) }
  let(:params) { { planting_ids: [seedling.id], status: 'given', recipient_name: 'Sam', given_on: '2026-11-14' } }
  let(:stall_planting) { owner.stall.stall_plantings.reload.first }

  before do
    sign_in owner
    # As in development: the form posts more than any one action permits, and that must not be an error.
    allow(ActionController::Parameters).to receive(:action_on_unpermitted_parameters).and_return(:raise)
  end

  # What the form island was given.
  def island_props
    JSON.parse(Capybara.string(response.body).find('[data-react-component=GiveAwayForm]', visible: :all)['data-props'])
  end

  describe 'GET /stall/plantings/new' do
    before { get new_stall_planting_path(status: 'given', planting_ids: [seedling.id]) }

    it 'offers the seedlings in the nursery' do
      expect(island_props['seedlings'].pluck('id')).to eq [seedling.id]
    end

    it 'says how many are in each batch' do
      expect(island_props['seedlings'].first['total']).to eq 6
    end

    it 'ticks the seedling it was opened for' do
      expect(island_props['selected']).to eq(seedling.id.to_s => nil)
    end

    it 'starts on the path it was opened for' do
      expect(island_props['status']).to eq 'given'
    end
  end

  describe 'POST /stall/plantings' do
    context 'with a seedling and a name' do
      before { post stall_plantings_path, params: }

      it 'goes back to the stall' do
        expect(response).to redirect_to(member_stall_path(owner))
      end

      it 'records who it was given to' do
        expect(stall_planting).to have_attributes(planting: seedling, recipient_name: 'Sam')
      end

      it 'takes it out of their active plantings' do
        expect(owner.plantings.active).not_to include(seedling)
      end
    end

    context 'with how they sign in' do
      before { post stall_plantings_path, params: params.merge(recipient_kind: 'email', recipient: 'Sam@Example.com') }

      it 'keeps the address, lower case' do
        expect(stall_planting).to have_attributes(recipient_kind: 'email', recipient: 'sam@example.com')
      end
    end

    context 'with a sign-in kind but no address' do
      before { post stall_plantings_path, params: params.merge(recipient_kind: 'email') }

      it 'records the name alone' do
        expect(stall_planting).to have_attributes(recipient_name: 'Sam', recipient: nil)
      end
    end

    context 'when given to a member' do
      before { post stall_plantings_path, params: params.except(:recipient_name).merge(recipient_member_id: neighbour.id) }

      it 'records the member' do
        expect(stall_planting.recipient_member).to eq neighbour
      end

      it 'is waiting for them' do
        expect(StallPlanting.waiting_for(neighbour)).to eq [stall_planting]
      end
    end

    context 'when given to yourself' do
      before { post stall_plantings_path, params: params.except(:recipient_name).merge(recipient_member_id: owner.id) }

      it 'asks again' do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when giving part of a batch' do
      before { post stall_plantings_path, params: params.merge(quantities: { seedling.id.to_s => '2' }) }

      it 'gives a planting of that many' do
        expect(stall_planting.planting.quantity).to eq 2
      end

      it 'keeps the rest in the nursery' do
        expect(seedling.reload.quantity).to eq 4
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

    context 'without saying who' do
      before { post stall_plantings_path, params: params.except(:recipient_name) }

      it { expect(response).to have_http_status(:unprocessable_content) }

      it 'gives nothing away' do
        expect(seedling.reload).not_to be_given_away
      end

      it 'shows the form again with what was chosen' do
        expect(island_props['selected']).to eq(seedling.id.to_s => nil)
      end
    end

    context 'without choosing a seedling' do
      before { post stall_plantings_path, params: params.merge(planting_ids: []) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path(status: 'given'))
      end
    end

    context 'with a planting that is not in the nursery' do
      before { post stall_plantings_path, params: params.merge(planting_ids: [garden_planting.id]) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path(status: 'given'))
      end
    end

    context "with someone else's planting" do
      before { post stall_plantings_path, params: params.merge(planting_ids: [create(:planting).id]) }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_planting_path(status: 'given'))
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
      owner.stall.give_away!([seedling], to: { recipient_name: 'Sam' })
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
