# frozen_string_literal: true

require 'rails_helper'

describe HomeController do
  # The invitation to the garden layout tool, at the top of the page.
  describe 'the garden layout invitation' do
    let(:member) { create(:member) }

    def invitation_href
      get root_path
      response.parsed_body.at_css('a.garden-layout-teaser-home')['href']
    end

    def layout_of(garden)
      layout_member_garden_path(garden.owner, garden)
    end

    it 'asks someone signed out to sign up' do
      expect(invitation_href).to eq new_member_registration_path
    end

    context 'when signed in' do
      before { sign_in member }

      it 'sends a member to the layout of their active garden with the most growing' do
        create(:garden, owner: member, name: 'Aardvark patch')
        busy = create(:garden, owner: member, name: 'Busy bed')
        create_list(:planting, 2, garden: busy, owner: member, quantity: 1)
        create(:inactive_garden, owner: member, name: 'Abandoned').tap do |old|
          create_list(:planting, 3, garden: old, owner: member, quantity: 1)
        end

        expect(invitation_href).to eq layout_of(busy)
      end

      # "apple corner" comes before the starting "Garden", whatever the case.
      it 'picks alphabetically between gardens with as much growing' do
        create(:garden, owner: member, name: 'Zinnia bed')
        first = create(:garden, owner: member, name: 'apple corner')

        expect(invitation_href).to eq layout_of(first)
      end

      # Every member starts with a garden called "Garden", so there is always
      # one of their own to compare with.
      it "only sends a member to one of their own gardens, however busy someone else's is" do
        mine = create(:garden, owner: member, name: 'Mine')
        create(:planting, garden: mine, owner: member, quantity: 1)
        theirs = create(:garden, name: 'Theirs')
        create_list(:planting, 3, garden: theirs, owner: theirs.owner, quantity: 1)

        expect(invitation_href).to eq layout_of(mine)
      end

      it 'asks a member with no active garden to add one' do
        member.gardens.find_each { |garden| garden.update!(active: false) }

        expect(invitation_href).to eq new_garden_path
      end
    end
  end
end
