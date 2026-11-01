# frozen_string_literal: true

require 'rails_helper'

describe Stalls::OpeningsController, flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:visitor) { create(:member) }

  describe 'POST /stall/opening' do
    context 'when signed in as the owner' do
      before do
        sign_in owner
        post stall_opening_path
      end

      it 'opens the stall' do
        expect(owner.reload.stall).to be_open
      end

      it 'goes to the stall' do
        expect(response).to redirect_to(member_stall_path(owner))
      end

      it 'says it is open' do
        expect(flash.notice).to eq('Your garden stall is open.')
      end
    end

    context 'when signed in as someone else' do
      before do
        sign_in visitor
        post stall_opening_path
      end

      it 'leaves the stall alone' do
        expect(owner.reload.stall).to be_nil
      end
    end

    context 'when signed out' do
      before { post stall_opening_path }

      it 'asks them to sign in' do
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end

  describe 'DELETE /stall/opening' do
    let!(:stall) { create(:stall, :open, member: owner) }

    context 'when signed in as the owner' do
      before do
        sign_in owner
        delete stall_opening_path
      end

      it 'closes the stall' do
        expect(stall.reload).not_to be_open
      end
    end

    context 'when signed in as someone else' do
      before do
        sign_in visitor
        delete stall_opening_path
      end

      it 'leaves the stall open' do
        expect(stall.reload).to be_open
      end
    end
  end
end
