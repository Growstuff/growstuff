# frozen_string_literal: true

require 'rails_helper'

describe StallsController, flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:visitor) { create(:member) }

  describe 'GET /members/:slug/stall' do
    context 'when signed in as the owner without a stall' do
      before do
        sign_in owner
        get member_stall_path(owner)
      end

      it 'invites them to open one' do
        expect(Capybara.string(response.body)).to have_button('Open my stall')
      end

      it 'shows the shutter' do
        expect(response.body).to include('stall-shutter')
      end
    end

    context 'when signed in as the owner with an open stall' do
      before do
        create(:stall, :open, member: owner)
        sign_in owner
        get member_stall_path(owner)
      end

      it 'asks what goes on first' do
        expect(Capybara.string(response.body)).to have_text('What goes on it first?')
      end

      it 'offers to close it' do
        expect(Capybara.string(response.body)).to have_button('Close the stall')
      end
    end

    context 'when a visitor looks at an open stall' do
      before do
        create(:stall, :open, member: owner)
        get member_stall_path(owner)
      end

      it 'shows the sign' do
        expect(response.body).to include("#{owner}&#39;s garden stall")
      end

      it 'has no button to close it' do
        expect(Capybara.string(response.body)).to have_no_button('Close the stall')
      end
    end

    context 'when a visitor looks at a closed stall' do
      before do
        create(:stall, member: owner)
        get member_stall_path(owner)
      end

      it 'is not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the feature is off', flipper: [] do
      before do
        Flipper.disable(:garden_stall)
        create(:stall, :open, member: owner)
        get member_stall_path(owner)
      end

      it 'is not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
