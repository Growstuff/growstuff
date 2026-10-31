# frozen_string_literal: true

require 'rails_helper'

describe 'Suggestions' do
  include_context 'signed in member'

  describe 'on my garden page' do
    before { visit garden_path(member.gardens.first) }

    it 'has no suggestions link without a location' do
      expect(page).to have_no_link href: suggestions_path
    end
  end

  describe 'on the plantings sidebar' do
    before { visit plantings_path }

    it 'offers to suggest something' do
      expect(page).to have_link 'Suggest something', href: suggestions_path
    end
  end
end
