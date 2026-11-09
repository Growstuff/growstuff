# frozen_string_literal: true

require 'rails_helper'

describe Admin::ClimateCoverageController do
  let(:admin) { create(:admin_member) }
  let(:page) { Capybara.string(response.body) }

  before { create(:climate_month, latitude: -41.25, longitude: 174.75) }

  context 'with an admin' do
    before do
      create(:member, login_name: 'wellington').update_columns(latitude: -41.3, longitude: 174.8) # rubocop:disable Rails/SkipsModelValidations
      create(:member, login_name: 'london').update_columns(latitude: 51.5, longitude: -0.1) # rubocop:disable Rails/SkipsModelValidations
      sign_in admin
    end

    describe 'members' do
      before { get admin_climate_members_path }

      it { expect(response).to have_http_status(:ok) }
      it { expect(page).to have_css('#status_covered .badge', text: '1') }
      it { expect(page).to have_css('tbody tr', text: 'wellington') }
    end

    describe 'members with a location' do
      before do
        create(:member, login_name: 'placed').update_columns(location: 'Wellington, New Zealand') # rubocop:disable Rails/SkipsModelValidations
        get admin_climate_members_path
      end

      it { expect(page).to have_link('Wellington, New Zealand', href: place_path('Wellington, New Zealand')) }
    end

    describe 'members covered through a garden' do
      before do
        create(:member, login_name: 'gardener').gardens.first.update_columns(latitude: -41.3, longitude: 174.8) # rubocop:disable Rails/SkipsModelValidations
        get admin_climate_members_path(status: 'covered')
      end

      it { expect(page).to have_css('tbody tr', text: 'gardener') }
    end

    describe 'members with out of date data' do
      before do
        create(:climate_month, latitude: 51.5, longitude: 0.0, updated_at: 2.months.ago)
        get admin_climate_members_path(status: 'stale')
      end

      it { expect(page).to have_css('tbody tr', text: 'london') }
      it { expect(page).to have_no_css('tbody tr', text: 'wellington') }
    end

    describe 'members with a status' do
      before { get admin_climate_members_path(status: 'missing') }

      it { expect(page).to have_css('tbody tr', text: 'london') }
      it { expect(page).to have_no_css('tbody tr', text: 'wellington') }
    end

    describe 'gardens' do
      before do
        create(:garden, name: 'Covered plot').update_columns(latitude: -41.3, longitude: 174.8) # rubocop:disable Rails/SkipsModelValidations
        get admin_climate_gardens_path(status: 'covered')
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(page).to have_css('tbody tr', text: 'Covered plot') }
    end
  end

  context 'with a member who is not an admin' do
    before do
      sign_in create(:member)
      get admin_climate_members_path
    end

    it { expect(response).not_to have_http_status(:ok) }
  end

  context 'without signing in' do
    before { get admin_climate_gardens_path }

    it { expect(response).to redirect_to new_member_session_path }
  end
end
