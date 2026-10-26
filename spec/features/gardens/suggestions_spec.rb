# frozen_string_literal: true

require 'rails_helper'

describe 'Suggestions on a garden page' do
  include_context 'signed in member'

  let(:garden) { member.gardens.first }

  context 'when viewing my own garden' do
    before { visit garden_path(garden) }

    it 'shows what to plant now' do
      expect(page).to have_css 'h2', text: 'What to plant now'
    end

    it 'asks where I garden when I have not said' do
      expect(page).to have_link 'Tell us where you garden', href: suggestions_path
    end
  end

  context 'when viewing someone else\'s garden' do
    before { visit garden_path(create(:garden)) }

    it 'has no suggestions' do
      expect(page).to have_no_css 'h2', text: 'What to plant now'
    end
  end

  context 'with the plantings sidebar' do
    before { visit plantings_path }

    it 'offers to suggest something' do
      expect(page).to have_link 'Suggest something', href: suggestions_path
    end
  end
end
