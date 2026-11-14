# frozen_string_literal: true

require 'rails_helper'

# The form is a React island, so these run in a browser.
describe 'Giving away seedlings', :js, flipper: :garden_stall do
  include_context 'signed in member'

  let!(:seedling) { create(:planting, owner: member, garden: member.nursery!, crop: create(:crop, name: 'kale'), quantity: 6) }

  describe 'putting them on the stall' do
    before do
      visit new_stall_planting_path(status: 'offered', planting_ids: [seedling.id])
      click_button 'Put on my stall'
      expect(page).to have_current_path(member_stall_path(member))
    end

    it 'puts the seedling on offer' do
      expect(member.reload.stall.seedlings_on_offer.map(&:planting)).to eq [seedling]
    end
  end

  describe 'recording that they were given to someone' do
    before do
      visit new_stall_planting_path(status: 'given', planting_ids: [seedling.id])
      click_button 'They\'re not on Growstuff: record their name instead'
      fill_in 'Their name', with: 'Sam from the garden'
      click_button 'Record as given away'
      expect(page).to have_current_path(member_stall_path(member))
    end

    it 'records who has them' do
      expect(member.reload.stall.stall_plantings.first.recipient_name).to eq 'Sam from the garden'
    end

    it 'takes the seedling out of the active plantings' do
      expect(seedling.reload).to be_given_away
    end
  end
end
