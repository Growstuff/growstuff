# frozen_string_literal: true

require 'rails_helper'

# The page someone lands on after signing up with a provider, to pick a name and agree to the terms.
describe 'Finishing sign up' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member, email: nil, email_optional: true, tos_agreement: nil) }
  let(:params) { { member: { login_name: 'alice_bsky', tos_agreement: '1', email: '' } } }

  before do
    create(:authentication, member:, provider: 'bluesky', uid: 'did:plc:abcdefghijklmnopqrstuvwx')
    sign_in member
  end

  describe 'GET' do
    before { get finish_signup_path(member) }

    it 'makes the email optional' do
      expect(response.body).to include('Email (optional)')
    end

    it 'leaves out the links to other sign in pages' do
      expect(response.body).not_to include('Forgot your password?')
    end
  end

  describe 'PATCH without an email' do
    before { patch finish_signup_path(member), params: }

    it 'finishes' do
      expect(response).to redirect_to(root_path)
    end

    it 'keeps the new login name' do
      expect(member.reload.login_name).to eq('alice_bsky')
    end

    it 'leaves the email blank' do
      expect(member.reload.email).to be_nil
    end
  end

  describe 'PATCH with an email' do
    let(:params) { { member: { login_name: 'alice_bsky', tos_agreement: '1', email: 'alice@example.com' } } }

    it 'sends a confirmation link' do
      expect { patch finish_signup_path(member), params: }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'does not use the address until it is confirmed' do
      patch finish_signup_path(member), params: {}

      expect(member.reload.email).to be_nil
    end

    it 'holds the address as unconfirmed' do
      patch finish_signup_path(member), params: params

      expect(member.reload.unconfirmed_email).to eq('alice@example.com')
    end
  end
end
