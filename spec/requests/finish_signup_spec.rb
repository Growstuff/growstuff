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

    it 'presents a required terms acceptance checkbox' do
      expect(response.parsed_body.at_css('input[type="checkbox"][name="member[tos_agreement]"][required]')).to be_present
    end

    it 'links to the terms of service' do
      expect(response.parsed_body.at_css("a[href='#{policy_tos_path}']")).to be_present
    end
  end

  describe 'translations' do
    %i(en de es fr ja zh).each do |locale|
      context "with locale #{locale}" do
        it 'renders without missing translations' do
          get finish_signup_path(member), params: { locale: }
          expect(response.parsed_body.css('.form-page .translation_missing')).to be_empty
        end

        it 'renders the existing email form without missing translations' do
          member.skip_reconfirmation!
          member.update!(email: 'alice@example.com')
          get finish_signup_path(member), params: { locale: }
          expect(response.parsed_body.css('.form-page .translation_missing')).to be_empty
        end
      end
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

    it 'records terms acceptance' do
      expect(member.reload).to be_tos_agreement
    end
  end

  context 'without terms acceptance' do
    it 'rejects an unchecked checkbox' do
      patch finish_signup_path(member), params: { member: { tos_agreement: '0' } }
      expect(member.reload).not_to be_tos_agreement
    end

    it 'rejects omitted acceptance' do
      patch finish_signup_path(member), params: { member: { login_name: 'new_name' } }
      expect(member.reload.login_name).not_to eq('new_name')
    end

    it 'keeps the acceptance form visible' do
      patch finish_signup_path(member), params: { member: { tos_agreement: '0' } }
      expect(response.parsed_body.at_css('input[type="checkbox"][name="member[tos_agreement]"][required]')).to be_present
    end
  end

  context 'when signed out' do
    before { sign_out member }

    it 'redirects to sign in' do
      get finish_signup_path(member)
      expect(response).to redirect_to new_member_session_path
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

  context 'with an email belonging to another member' do
    let(:existing_member) { create(:member) }
    let(:params) { { member: { login_name: 'alice_bsky', tos_agreement: '1', email: existing_member.email } } }

    it 'redisplays the form with an email error' do
      patch finish_signup_path(member), params: params
      expect(response.parsed_body.at_css('input[name="member[email]"].is-invalid')).to be_present
    end

    it 'does not save any signup changes' do
      original_attributes = member.attributes.slice('email', 'unconfirmed_email', 'login_name', 'tos_agreement')
      patch finish_signup_path(member), params: params
      expect(member.reload.attributes.slice(*original_attributes.keys)).to eq(original_attributes)
    end

    it 'does not send a confirmation email' do
      existing_member
      expect { patch finish_signup_path(member), params: }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'does not change the other account' do
      original_attributes = existing_member.reload.attributes
      patch finish_signup_path(member), params: params
      expect(existing_member.reload.attributes).to eq(original_attributes)
    end

    it 'allows retrying without an email' do
      patch finish_signup_path(member), params: params
      patch finish_signup_path(member), params: { member: { login_name: 'alice_bsky', tos_agreement: '1', email: '' } }
      expect(response).to redirect_to(root_path)
    end
  end
end
