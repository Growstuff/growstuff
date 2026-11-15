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
      find_by_id('stall-offer-h') # the stall it goes back to, so the server has finished
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
      find_by_id('stall-given-h') # the stall it goes back to, so the server has finished
    end

    it 'records who has them' do
      expect(member.reload.stall.stall_plantings.first.recipient_name).to eq 'Sam from the garden'
    end

    it 'takes the seedling out of the active plantings' do
      expect(seedling.reload).to be_given_away
    end
  end
end
