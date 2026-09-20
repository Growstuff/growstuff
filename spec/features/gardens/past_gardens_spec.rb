# frozen_string_literal: true

require 'rails_helper'

describe "A member's past gardens" do
  let(:owner) { create(:member, login_name: 'gardener') }
  let(:tomato) { create(:tomato) }
  let!(:retired) { create(:inactive_garden, owner: owner, name: 'Old plot', description: 'Where it all began') }
  let!(:current) { create(:garden, owner: owner, name: 'Current plot') }

  before do
    create(:planting, owner: owner, garden: retired, crop: tomato, planted_at: Date.new(2021, 10, 1))
    create(:planting, owner: owner, garden: retired, crop: create(:maize), planted_at: Date.new(2023, 2, 1))
  end

  context 'when nobody is signed in' do
    before { visit member_past_gardens_path(owner) }

    it 'shows only the inactive gardens, with when they were used and what was grown' do
      expect(page).to have_link 'Old plot', href: garden_path(retired)
      expect(page).to have_no_text 'Current plot'
      expect(page).to have_text '2021–2023 · 2 plantings'
      expect(page).to have_text 'Where it all began'
      expect(page).to have_link tomato.name, href: crop_path(tomato)
    end

    it 'does not offer to reactivate' do
      expect(page).to have_no_link 'Mark as active'
    end

    it 'links back to the current gardens' do
      expect(page).to have_link 'Current gardens', href: member_gardens_path(owner)
    end
  end

  context 'when the owner is signed in' do
    include_context 'signed in member'
    let(:owner) { member }

    before { visit member_past_gardens_path(owner) }

    it 'lets them reactivate a garden' do
      click_link 'Mark as active'

      expect(retired.reload).to be_active
    end
  end

  context "when someone else's past gardens" do
    include_context 'signed in member'

    before { visit member_past_gardens_path(owner) }

    it 'does not let a signed in visitor reactivate them' do
      expect(page).to have_link 'Old plot'
      expect(page).to have_no_link 'Mark as active'
    end
  end

  context 'with no past gardens' do
    before { visit member_past_gardens_path(create(:member)) }

    it 'says so' do
      expect(page).to have_text 'There are no past gardens to show.'
    end
  end
end
