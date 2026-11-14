# frozen_string_literal: true

require 'rails_helper'

describe Stalls::GiftsController, flipper: :garden_stall do
  let(:neighbour) { create(:member, email: 'neighbour@example.com') }
  let!(:gift) { create(:stall_planting) }

  before { sign_in neighbour }

  describe 'GET /gifts' do
    before { get gifts_path }

    it 'offers to claim what was given to them' do
      expect(Capybara.string(response.body)).to have_button
    end
  end

  describe 'POST /gifts/:id/acceptance' do
    let(:garden) { neighbour.gardens.first }

    context 'when given to them' do
      before { post gift_acceptance_path(gift), params: { garden_id: garden.id } }

      it 'shows them the planting' do
        expect(response).to redirect_to(gift.planting)
      end

      it 'puts it in their garden' do
        expect(gift.planting.reload.garden).to eq garden
      end
    end

    context 'when given to someone else' do
      let!(:gift) { create(:stall_planting, recipient: 'other@example.com') }

      it 'is not found' do
        post gift_acceptance_path(gift), params: { garden_id: garden.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with someone else's garden" do
      before { post gift_acceptance_path(gift), params: { garden_id: create(:garden).id } }

      it 'goes back to the gifts' do
        expect(response).to redirect_to(gifts_path)
      end

      it 'leaves the planting with the giver' do
        expect(gift.planting.reload).to be_given_away
      end
    end
  end
end
