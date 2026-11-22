# frozen_string_literal: true

require 'rails_helper'

describe 'Terms acceptance' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }

  context 'when signed in without recorded acceptance' do
    before do
      member.update!(tos_agreement: nil)
      sign_in member
    end

    it 'redirects ordinary requests to finish signup' do
      get root_path
      expect(response).to redirect_to finish_signup_path(member)
    end

    it 'blocks account changes until acceptance' do
      patch member_registration_path, params: { member: { bio: 'Changed' } }
      expect(member.reload.bio).not_to eq('Changed')
    end

    it 'allows the acceptance page' do
      get finish_signup_path(member)
      expect(response).to have_http_status(:ok)
    end

    it 'allows reading the terms' do
      get policy_tos_path
      expect(response).to have_http_status(:ok)
    end

    it 'allows signing out' do
      delete destroy_member_session_path, headers: { 'HTTP_REFERER' => finish_signup_url(member) }
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it 'allows normal navigation after accepting' do
      patch finish_signup_path(member), params: { member: { tos_agreement: '1' } }
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when signing in without recorded acceptance' do
    before { member.update!(tos_agreement: nil) }

    it 'redirects password sign in to finish signup' do
      post member_session_path, params: { member: { login: member.login_name, password: member.password } }
      expect(response).to redirect_to finish_signup_path(member)
    end
  end

  context 'with recorded acceptance' do
    before { sign_in member }

    it 'allows normal navigation' do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when signed out' do
    it 'allows normal navigation' do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
