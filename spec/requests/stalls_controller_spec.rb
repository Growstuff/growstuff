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

    context 'when the owner has just opened the stall' do
      before do
        sign_in owner
        post stall_opening_path
        follow_redirect!
      end

      it 'rolls the shutter up' do
        expect(Capybara.string(response.body)).to have_css('.stall-opening')
      end
    end

    context 'when there are packets on the stall' do
      before do
        stall = create(:stall, :open, member: owner)
        stall.put_seeds_on!([create(:seed, owner:, crop: create(:crop, name: 'rocket'))])
        sign_in owner
        get member_stall_path(owner)
      end

      it 'shows the seed tin' do
        expect(Capybara.string(response.body)).to have_css('.stall-section .seed-card', text: 'rocket')
      end

      it 'says the packet is free' do
        expect(Capybara.string(response.body)).to have_css('.stall-tin-item .stall-offer-free', text: 'Free')
      end

      it 'lets the owner take a packet off' do
        expect(Capybara.string(response.body)).to have_button('Take off the stall')
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

      it 'has a share image for Bluesky and the fediverse' do
        expect(Capybara.string(response.body)).to have_css('meta[property="og:image"][content*="stall-card"]', visible: :all)
      end

      it 'has a share title with the name' do
        expect(Capybara.string(response.body)).to have_css("meta[property='og:title'][content=\"#{owner}'s garden stall\"]", visible: :all)
      end

      it 'has links to share it' do
        expect(Capybara.string(response.body)).to have_css('.shareon a.bluesky')
      end

      it 'tells them what Growstuff is' do
        expect(Capybara.string(response.body)).to have_css('.stall-about', text: 'A community for growing food')
      end

      it 'has no button to close it' do
        expect(Capybara.string(response.body)).to have_no_button('Close the stall')
      end
    end

    context 'when a packet is on the stall' do
      let(:stall_seed) { create(:stall_seed, stall: create(:stall, :open, member: owner, claim_area: 'anywhere')) }
      let(:friend) { create(:member) }

      before { stall_seed }

      it 'asks a visitor to sign in to claim' do
        get member_stall_path(owner)
        expect(Capybara.string(response.body)).to have_link('Sign in to claim')
      end

      it 'lets a member claim it' do
        sign_in friend
        get member_stall_path(owner)
        expect(Capybara.string(response.body)).to have_css('.stall-claim summary', text: 'Claim')
      end

      it 'does not offer the owner a claim' do
        sign_in owner
        get member_stall_path(owner)
        expect(Capybara.string(response.body)).to have_no_css('.stall-claim')
      end

      context 'when it has been claimed' do
        before do
          create(:claim, stall_seed:, member: friend)
          sign_in friend
          get member_stall_path(owner)
        end

        it 'shows the ribbon with their name' do
          expect(Capybara.string(response.body)).to have_css('.stall-ribbon', text: friend.login_name)
        end

        it 'lets them undo it' do
          expect(Capybara.string(response.body)).to have_button('Undo my claim')
        end

        it 'takes the claim button away' do
          expect(Capybara.string(response.body)).to have_no_css('.stall-claim')
        end
      end
    end

    context 'when the stall is only for people nearby' do
      before do
        Geocoder::Lookup::Test.add_stub('Wellington, Wellington Region, New Zealand', [{ 'coordinates' => [-41.29, 174.78] }])
        owner.update!(location: 'Wellington, Wellington Region, New Zealand')
        create(:stall, :open, member: owner, claim_area: 'region', postage: true)
        get member_stall_path(owner)
      end

      it 'says who can claim' do
        expect(Capybara.string(response.body)).to have_css('.stall-terms', text: 'only for people near Wellington')
      end

      it 'says the gardener may ask for postage' do
        expect(Capybara.string(response.body)).to have_css('.stall-terms', text: 'may ask you to pay for postage')
      end

      it 'reminds them to offer something in return' do
        expect(Capybara.string(response.body)).to have_css('.stall-terms', text: 'offer something in return')
      end
    end

    context 'when a member looks at an open stall' do
      before do
        create(:stall, :open, member: owner)
        sign_in visitor
        get member_stall_path(owner)
      end

      it 'leaves out the note about Growstuff' do
        expect(Capybara.string(response.body)).to have_no_css('.stall-about')
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
