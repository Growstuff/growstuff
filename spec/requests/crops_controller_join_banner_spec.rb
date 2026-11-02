# frozen_string_literal: true

require 'rails_helper'

describe CropsController do
  describe 'GET /crops/:slug' do
    let(:crop) { create(:crop, name: 'tomato', description: 'A red berry.') }
    let(:page) { Capybara.string(response.body) }

    context 'when signed out' do
      before { get crop_path(crop) }

      it 'explains what Growstuff is' do
        expect(page).to have_css('.crop-join-banner', text: 'Growstuff is a free, community-run site for people who grow food.')
      end

      it 'invites people to join' do
        expect(page).to have_css('.crop-join-banner a.btn-signup', text: 'Join free')
      end

      it 'offers to sign in' do
        expect(page).to have_css('.crop-join-banner a', text: 'Sign in')
      end

      it 'comes after the description' do
        expect(response.body.index('A red berry.')).to be < response.body.index('crop-join-banner')
      end

      it 'comes before the growing facts' do
        expect(response.body.index('crop-join-banner')).to be < response.body.index('class="prediction"')
      end
    end

    context 'when signed in' do
      before do
        sign_in create(:member)
        get crop_path(crop)
      end

      it 'is not shown' do
        expect(page).to have_no_css('.crop-join-banner')
      end
    end

    describe 'the last edited line' do
      before { get crop_path(crop) }

      it 'is aligned to the right' do
        expect(page).to have_css('.crop-last-edit.text-end')
      end

      it 'is at the top, before the banner' do
        expect(response.body.index('crop-last-edit')).to be < response.body.index('crop-join-banner')
      end
    end
  end
end
