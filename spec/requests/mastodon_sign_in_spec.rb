# frozen_string_literal: true

require 'rails_helper'

describe 'Signing in with Mastodon' do
  include Devise::Test::IntegrationHelpers

  let(:domain) { 'mastodon.social' }
  let(:uid) { ['111', domain].join('@') }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(provider: 'mastodon', uid: '111',
                           info: { nickname: 'alice', name: 'alice', image: 'https://mastodon.social/avatar.png',
                                   urls: { 'Profile' => "https://#{domain}/@alice" } },
                           credentials: { token: 'private-token' })
  end

  before { OmniAuth.config.mock_auth[:mastodon] = auth_hash }
  after { OmniAuth.config.mock_auth[:mastodon] = nil }

  def callback(tos: '1')
    post member_mastodon_omniauth_authorize_path, params: { identifier: ['alice', domain].join('@'), tos_agreement: tos }
    get member_mastodon_omniauth_callback_path
  end

  context 'when new to Growstuff' do
    it 'creates a member' do
      expect { callback }.to change(Member, :count).by(1)
    end

    it 'does not require an email' do
      callback
      expect(Member.last.email).to be_nil
    end

    it 'suggests the username as the login name' do
      callback
      expect(Member.last.login_name).to eq 'alice'
    end

    it 'leaves the username for the member to confirm' do
      callback
      expect(Member.last).to be_username_unconfirmed
    end

    it 'links the server-qualified identity' do
      callback
      expect(Member.last.auth('mastodon').uid).to eq uid
    end

    it 'does not store the access token' do
      callback
      expect(Member.last.auth('mastodon').token).to be_nil
    end

    it 'records agreement to the terms' do
      callback
      expect(Member.last.tos_agreement).to be true
    end

    it 'starts onboarding on the home page' do
      callback
      expect(response).to redirect_to root_path
    end

    it 'signs the new member in' do
      callback
      get edit_member_registration_path
      expect(response).to have_http_status(:ok)
    end

    it 'refuses signup without agreeing to the terms' do
      expect { callback(tos: nil) }.not_to change(Member, :count)
    end

    context 'with another member without an email' do
      before { create(:member, email: nil, email_optional: true) }

      it 'creates a separate account' do
        expect { callback }.to change(Member, :count).by(1)
      end
    end
  end

  context 'when returning to a linked account' do
    let(:member) { create(:member, email: nil, email_optional: true) }

    before { create(:mastodon_authentication, member:, uid:, name: 'Old name') }

    it 'does not create another member' do
      expect { callback(tos: nil) }.not_to change(Member, :count)
    end

    it 'signs in without agreeing to the terms again' do
      callback(tos: nil)
      get edit_member_registration_path
      expect(response).to have_http_status(:ok)
    end

    it 'refreshes the displayed handle' do
      callback
      expect(member.auth('mastodon').name).to eq ['@alice', domain].join('@')
    end
  end

  context 'when the same numeric identity exists on another server' do
    before { create(:mastodon_authentication, uid: ['111', 'example.social'].join('@')) }

    it 'creates a separate account' do
      expect { callback }.to change(Member, :count).by(1)
    end
  end

  describe 'entry points' do
    it 'opens the Mastodon dialog from the home page' do
      get root_path
      expect(response.parsed_body.at_css('a[data-auth-dialog="mastodon"]').text).to include 'Sign in with Mastodon'
    end

    it 'offers a form on the sign in page without JavaScript' do
      get new_member_session_path
      expect(response.parsed_body.at_css('form[action="/members/auth/mastodon"] input[name="identifier"]')).to be_present
    end

    it 'offers a form on the sign up page without JavaScript' do
      get new_member_registration_path
      expect(response.parsed_body.at_css('form[action="/members/auth/mastodon"] input[name="tos_agreement"][required]')).to be_present
    end
  end

  describe 'disconnecting' do
    let(:member) { create(:member, email: nil, email_optional: true) }
    let!(:authentication) { create(:mastodon_authentication, member:) }

    before { sign_in member }

    it 'keeps the only way a member without an email can sign in' do
      expect { delete authentication_path(authentication) }.not_to change(Authentication, :count)
    end
  end
end
