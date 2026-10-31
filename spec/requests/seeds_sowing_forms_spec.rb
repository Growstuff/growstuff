# frozen_string_literal: true

require 'rails_helper'

# The standalone forms for a seed: the page to add one, and the page to edit one.
describe SeedsController, 'the standalone forms' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create_located_member('Sowing forms southern town', -41.3, 174.8) }
  let(:page) { Capybara.string(response.body) }

  describe '#new' do
    before do
      sign_in member
      get new_seed_path
    end

    it('renders') { expect(response).to have_http_status(:ok) }
    it('has the months to sow in, to tick') { expect(page).to have_css('.sow-months-chips input[type=checkbox]', count: 12) }
    it('asks how to sow') { expect(page).to have_css('textarea[name="seed[how_to_sow]"]') }
    it('asks for the germination range') { expect(page).to have_css('input[name="seed[germination_days_min]"], input[name="seed[germination_days_max]"]', count: 2) }

    it('offers the seasons for the hemisphere of the member filling it in, there being no owner yet') do
      expect(page).to have_css('[data-sow-months-season="9,10,11"]', text: 'Spring')
    end
  end

  describe '#new for a member we do not know the whereabouts of' do
    let(:member) { create(:member, location: nil) }

    before do
      sign_in member
      get new_seed_path
    end

    it('renders') { expect(response).to have_http_status(:ok) }
    it('has no season shortcuts, rather than a guess') { expect(page).to have_no_css('[data-sow-months-season]') }
  end

  describe '#edit' do
    let(:seed) { create(:seed, owner: member, sow_months: [10, 11]) }

    before do
      sign_in member
      get edit_seed_path(seed)
    end

    it('renders') { expect(response).to have_http_status(:ok) }
    it('has the months it says ticked') { expect(page).to have_css('.sow-months-chips input[checked][value="10"]') }
  end

  describe '#edit by an admin, for someone else\'s seed' do
    let(:seed) { create(:seed, owner: member) }
    let(:admin) { create(:admin_member, location: nil) }

    before do
      sign_in admin
      get edit_seed_path(seed)
    end

    it('offers the seasons for the hemisphere of the seed\'s owner') do
      expect(page).to have_css('[data-sow-months-season="9,10,11"]', text: 'Spring')
    end
  end
end
