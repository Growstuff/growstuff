# frozen_string_literal: true

require 'rails_helper'

describe 'Starting to sign in with Mastodon' do
  let(:client_service) { instance_double(MastodonClientService) }

  before do
    OmniAuth.config.test_mode = false
    allow(MastodonClientService).to receive(:new).and_return(client_service)
  end

  after { OmniAuth.config.test_mode = true }

  context 'with a valid Mastodon address' do
    let(:identifier) { ['alice', 'mastodon.social'].join('@') }

    before do
      allow(client_service).to receive(:credentials_for).and_return(%w(client-id client-secret))
      post member_mastodon_omniauth_authorize_path, params: { identifier:, tos_agreement: '1' }
    end

    it 'sends the member to their server' do
      expect(URI.parse(response.location).host).to eq 'mastodon.social'
    end

    it 'only requests permission to read account information' do
      expect(Rack::Utils.parse_query(URI.parse(response.location).query)['scope']).to eq 'read:accounts'
    end

    context 'with a leading @' do
      let(:identifier) { ['@alice', 'mastodon.social'].join('@') }

      it 'registers with the account server rather than the username' do
        expect(client_service).to have_received(:credentials_for).with('mastodon.social', anything)
      end
    end
  end

  context 'with CSRF protection behind the Codespaces development proxy' do
    around do |example|
      original_protection = ActionController::Base.allow_forgery_protection
      original_origin_check = ActionController::Base.forgery_protection_origin_check
      ActionController::Base.allow_forgery_protection = true
      ActionController::Base.forgery_protection_origin_check = false
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_protection
      ActionController::Base.forgery_protection_origin_check = original_origin_check
    end

    let(:headers) { { 'HTTP_ORIGIN' => 'https://localhost:3000' } }
    let(:identifier) { ['alice', 'mastodon.social'].join('@') }

    before do
      host! 'example-3000.app.github.dev'
      https!
      allow(client_service).to receive(:credentials_for).and_return(%w(client-id client-secret))
    end

    it 'accepts the token rendered by the form despite the rewritten origin' do
      get new_member_session_path
      form = Nokogiri::HTML(response.body).at_css('form[action="/members/auth/mastodon"]')
      token = form.at_css('input[name="authenticity_token"]')['value']

      post member_mastodon_omniauth_authorize_path, params: { identifier:, authenticity_token: token }, headers: headers

      expect(URI.parse(response.location).host).to eq 'mastodon.social'
    end

    it 'rejects a request without an authenticity token' do
      post member_mastodon_omniauth_authorize_path, params: { identifier: }, headers: headers

      expect(client_service).not_to have_received(:credentials_for)
    end

    it 'rejects the rewritten origin when origin checking is enabled even with a valid token' do
      ActionController::Base.forgery_protection_origin_check = true
      get new_member_session_path
      form = Nokogiri::HTML(response.body).at_css('form[action="/members/auth/mastodon"]')
      token = form.at_css('input[name="authenticity_token"]')['value']

      post member_mastodon_omniauth_authorize_path, params: { identifier:, authenticity_token: token }, headers: headers

      expect(client_service).not_to have_received(:credentials_for)
    end
  end

  context 'when the server cannot be reached' do
    before do
      allow(client_service).to receive(:credentials_for).and_raise(MastodonClientService::Error, 'unreachable')
    end

    it 'explains the failure without raising an exception' do
      post member_mastodon_omniauth_authorize_path, params: { identifier: ['alice', 'mastodon.social'].join('@') }
      follow_redirect! if response.redirect?

      expect(flash[:alert]).to eq I18n.t('messages.mastodon_instance_invalid')
    end
  end

  context 'when the callback state does not match' do
    before do
      allow(client_service).to receive(:credentials_for).and_return(%w(client-id client-secret))
      post member_mastodon_omniauth_authorize_path, params: { identifier: ['alice', 'mastodon.social'].join('@') }
    end

    it 'refuses the callback' do
      get member_mastodon_omniauth_callback_path, params: { code: 'untrusted-code', state: 'wrong-state' }

      expect(flash[:alert]).to eq I18n.t('messages.mastodon_failed')
    end
  end

  context 'when authorization is declined' do
    before do
      allow(client_service).to receive(:credentials_for).and_return(%w(client-id client-secret))
      post member_mastodon_omniauth_authorize_path, params: { identifier: ['alice', 'mastodon.social'].join('@') }
      state = Rack::Utils.parse_query(URI.parse(response.location).query)['state']
      get member_mastodon_omniauth_callback_path, params: { error: 'access_denied', state: }
    end

    it 'explains that authorization was not approved' do
      expect(flash[:alert]).to eq I18n.t('messages.mastodon_declined')
    end
  end
end
