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

    it 'lists confirming the email, to come once they have added one' do
      expect(response.body).to include('send you a link to confirm it')
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

    it 'answers the page script without a redirect' do
      post decline_member_email_path, as: :json

      expect(response).to have_http_status(:no_content)
    end

    it 'remembers they said no' do
      expect(member.reload).to be_email_declined
    end

    it 'drops confirming the email from the list' do
      get root_path

      expect(response.body).not_to include('Confirm your email address')
    end

    it 'keeps the step on the list, as done' do
      get root_path

      expect(response.body).to include("You chose not to add one")
    end

    it 'offers a link to change their mind' do
      get root_path

      expect(response.body).to include('Changed your mind?')
    end

    it 'keeps the email form hidden until they follow it' do
      get root_path

      expect(response.body).not_to include('name="member[email]"')
    end

    it 'shows the email form once they change their mind' do
      get root_path(add_email: 1)

      expect(response.body).to include('name="member[email]"')
    end

    it 'lets them say no thanks again' do
      get root_path(add_email: 1)

      expect(response.body).to include('btn-outline-secondary')
    end

    it 'hands the row to the page script, which does this in place' do
      get root_path

      expect(response.body).to include('data-react-component="EmailStep"')
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

  describe 'the Add a photo step' do
    let(:href) { response.parsed_body.at_css('a[href^="/photos/new"]')&.[]('href') }

    before { get root_path }

    it 'links the photo to their garden' do
      expect(href).to eq(new_photo_path(type: 'garden', id: member.gardens.first.id))
    end

    it 'goes to a page that works' do
      get href

      expect(response).to have_http_status(:ok)
    end
  end
end
