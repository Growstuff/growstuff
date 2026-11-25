# frozen_string_literal: true

require 'rails_helper'

describe ConfirmationsController, type: :request do
  let(:member) { create(:member, confirmed_at: nil, confirmation_sent_at: Time.zone.now) }
  let(:link) { member_confirmation_path(confirmation_token: member.confirmation_token) }

  # Signing up in this browser leaves what ConfirmationsController looks for in its session.
  def sign_up
    attributes = attributes_for(:member).slice(:login_name, :email, :password).merge(password_confirmation: 'password1', tos_agreement: '1')
    post member_registration_path, params: { member: attributes }
    Member.find_by!(login_name: attributes[:login_name])
  end

  context 'with the link opened in another browser' do
    before { get link }

    it { expect(response).to redirect_to new_member_session_path(login: member.login_name) }
  end

  context 'with the link opened in the browser that signed up' do
    let(:member) { sign_up }

    before { get member_confirmation_path(confirmation_token: member.confirmation_token) }

    it { expect(response).to redirect_to root_path }

    it 'signs them in' do
      get root_path
      expect(controller.current_member).to eq member
    end
  end

  describe 'sign in page with a login name' do
    before { get new_member_session_path(login: 'Marigold') }

    it 'fills in the login' do
      expect(response.body).to include 'value="Marigold"'
    end
  end
end
