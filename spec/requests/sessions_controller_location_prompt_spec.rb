# frozen_string_literal: true

require 'rails_helper'

describe SessionsController do
  let(:password) { 'password1234' }
  let(:member) { create(:member, password:, password_confirmation: password) }

  before { member.update_columns(location:, latitude:, longitude: latitude) } # rubocop:disable Rails/SkipsModelValidations

  def sign_in_member
    post member_session_path, params: { member: { login: member.login_name, password: } }
    follow_redirect!
  end

  context 'when signing in with a location that never got coordinates' do
    let(:location) { 'porirua, wellington' }
    let(:latitude) { nil }

    it 'asks them to choose a place' do
      sign_in_member
      expect(response.body).to include('Choose your location from the list')
    end
  end

  context 'with a place on the map' do
    let(:location) { 'Wellington, New Zealand' }
    let(:latitude) { -41.3 }

    it 'does not ask' do
      sign_in_member
      expect(response.body).not_to include('Choose your location from the list')
    end
  end

  context 'without a location' do
    let(:location) { '' }
    let(:latitude) { nil }

    it 'does not ask' do
      sign_in_member
      expect(response.body).not_to include('Choose your location from the list')
    end
  end
end
