# frozen_string_literal: true

require 'rails_helper'

describe HomeHelper do
  describe '#garden_layout_invitation' do
    let(:member) { create(:member) }
    let(:garden) { create(:garden, owner: member, name: 'Back bed') }

    it "sends a member with a garden to that garden's layout" do
      allow(helper).to receive(:member_signed_in?).and_return(true)
      invitation = helper.garden_layout_invitation(garden)

      expect(invitation[:href]).to eq "/members/#{member.slug}/gardens/#{garden.slug}/layout"
      expect(invitation[:heading]).to eq 'Map out Back bed'
      expect(invitation[:cta]).to eq 'Try out the new garden layout tool →'
    end

    it 'asks a member with no active garden to add one first' do
      allow(helper).to receive(:member_signed_in?).and_return(true)

      expect(helper.garden_layout_invitation(nil)).to include(href: '/gardens/new', cta: 'Add a garden →')
    end

    it 'asks someone signed out to sign up' do
      allow(helper).to receive(:member_signed_in?).and_return(false)

      expect(helper.garden_layout_invitation(nil)).to include(href: '/members/sign_up', cta: 'Sign up to try it →')
    end
  end
end
