# frozen_string_literal: true

require 'rails_helper'

# The home page to-do list for finishing joining: name, email, confirming it.
describe 'Setup to-do list' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member, email: nil, email_optional: true, settings: { 'username' => 'unconfirmed' }) }

  before do
    create(:authentication, member:, provider: 'bluesky', uid: 'did:plc:abcdefghijklmnopqrstuvwx')
    sign_in member
  end

  describe 'the home page' do
    before { get root_path }

    it 'asks them to confirm their name' do
      expect(response.body).to include('Confirm your name')
    end

    it 'asks for an email' do
      expect(response.body).to include('Add your email address')
    end

    it 'says what they miss without one' do
      expect(response.body).to include('send you notifications')
    end

    it 'does not show the list to a member with nothing to do' do
      sign_in create(:member)
      get root_path

      expect(response.body).not_to include('Confirm your name')
    end
  end

  describe 'PATCH /my/name' do
    it 'saves the name' do
      patch member_name_path, params: { member: { login_name: 'alice_garden' } }

      expect(member.reload.login_name).to eq('alice_garden')
    end

    it 'marks it confirmed' do
      patch member_name_path, params: { member: { login_name: 'alice_garden' } }

      expect(member.reload).not_to be_username_unconfirmed
    end

    it 'keeps the to-do for a name that will not do' do
      patch member_name_path, params: { member: { login_name: 'a' } }

      expect(member.reload).to be_username_unconfirmed
    end
  end

  describe 'PATCH /my/email' do
    it 'sends a confirmation link' do
      expect { patch member_email_path, params: { member: { email: 'alice@example.com' } } }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'holds the address as unconfirmed' do
      patch member_email_path, params: { member: { email: 'alice@example.com' } }

      expect(member.reload.unconfirmed_email).to eq('alice@example.com')
    end

    it 'asks again for a blank address' do
      patch member_email_path, params: { member: { email: '' } }

      expect(flash[:alert]).to eq(I18n.t('member_emails.update.blank'))
    end
  end

  describe 'POST /my/email/decline' do
    before { post decline_member_email_path }

    it 'remembers they said no' do
      expect(member.reload).to be_email_declined
    end

    it 'stops asking for an email' do
      get root_path

      expect(response.body).not_to include('Add your email address')
    end
  end

  describe 'confirming the email' do
    before do
      patch member_email_path, params: { member: { email: 'alice@example.com' } }
      member.update_columns(confirmation_sent_at: 2.minutes.ago) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'shows the to-do until it is confirmed' do
      get root_path

      expect(response.body).to include('Confirm your email address')
    end

    it 'sends the link again' do
      expect { post resend_member_email_path }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'does not resend straight away' do
      member.update_columns(confirmation_sent_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      expect { post resend_member_email_path }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
