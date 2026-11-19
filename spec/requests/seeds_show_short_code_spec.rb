# frozen_string_literal: true

require 'rails_helper'

# The code the owner writes on a packet, with the help for what it is for.
describe 'Seed short code on the packet page', flipper: :planting_codes do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed, short_code: 'T2B3') }
  let(:page) { Capybara.string(response.body) }

  context 'when the owner looks' do
    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('has the code row translated') { expect(page).to have_no_css('.packet-facts .translation_missing') }
    it('shows the code') { expect(page).to have_css('.fact-row .seedfacts--shortcode', text: 'T2B3') }
    it('explains it in a help popover') { expect(page).to have_css('.seedshortcode--help[data-bs-content*="give seeds or seedlings"]') }
  end

  context 'when the packet has no code' do
    before do
      seed.update_column(:short_code, nil) # rubocop:disable Rails/SkipsModelValidations
      sign_in seed.owner
      get seed_path(seed)
    end

    it('shows the packet') { expect(response).to have_http_status(:ok) }
    it('shows no code') { expect(page).to have_no_css('.seedfacts--shortcode') }
  end

  context 'when another member looks' do
    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('does not show the code') { expect(page).to have_no_css('.seedfacts--shortcode') }
  end

  context 'when nobody is signed in' do
    before { get seed_path(seed) }

    it('does not show the code') { expect(page).to have_no_css('.seedfacts--shortcode') }
  end

  context 'when the owner has the packets listed' do
    before do
      sign_in seed.owner
      get member_seeds_path(seed.owner, view: 'list')
    end

    it('shows the response') { expect(response).to have_http_status(:ok) }
  end
end
