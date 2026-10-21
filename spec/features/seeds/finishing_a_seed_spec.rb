# frozen_string_literal: true

require 'rails_helper'

describe 'Finishing a seed', :js do
  include_context 'signed in member'

  describe 'with the finished checkbox on the form' do
    before do
      visit new_seed_path
      find_by_id('seed_finished_at').set('2014-08-30')
      check 'Mark as finished'
      uncheck 'Mark as finished'
    end

    it 'clears the finished date when unchecked' do
      expect(find_by_id('seed_finished_at').value).to eq ''
    end

    it 'restores the finished date when checked again' do
      check 'Mark as finished'
      expect(find_by_id('seed_finished_at').value).to eq '2014-08-30'
    end
  end

  describe 'with the actions menu' do
    let!(:seed) { create(:seed, owner: member) }

    before do
      visit seed_path(seed)
      click_link 'Actions'
      click_link 'Mark as finished'
    end

    it 'asks to confirm without a date' do
      expect(page).to have_link 'Confirm without date'
    end

    it 'finishes the seed when confirmed without a date' do
      click_link 'Confirm without date'
      expect(page).to have_content 'Finished'
    end
  end
end
