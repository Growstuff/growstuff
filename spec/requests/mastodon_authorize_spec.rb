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
    before do
      allow(client_service).to receive(:credentials_for).and_return(%w(client-id client-secret))
      post member_mastodon_omniauth_authorize_path, params: { identifier: ['alice', 'mastodon.social'].join('@'), tos_agreement: '1' }
    end

    it 'sends the member to their server' do
      expect(URI.parse(response.location).host).to eq 'mastodon.social'
    end

    it 'only requests permission to read account information' do
      expect(Rack::Utils.parse_query(URI.parse(response.location).query)['scope']).to eq 'read:accounts'
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
end
