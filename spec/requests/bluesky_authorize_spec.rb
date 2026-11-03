# frozen_string_literal: true

require 'rails_helper'

# Goes through the real strategy; OmniAuth's test mode would skip it.
describe 'Starting to sign in with Bluesky' do
  let(:client) { instance_double(Atproto::OauthClient) }

  before do
    OmniAuth.config.test_mode = false
    allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key)
    allow(Atproto::OauthClient).to receive(:new).and_return(client)
  end

  after { OmniAuth.config.test_mode = true }

  context 'with a handle that resolves' do
    before { allow(client).to receive(:begin_authorization).with('alice.bsky.social').and_return(['https://auth.test/authorize?x=1', { 'state' => 's' }]) }

    it 'sends them to their authorization server' do
      post member_bluesky_omniauth_authorize_path, params: { handle: 'alice.bsky.social' }

      expect(response).to redirect_to('https://auth.test/authorize?x=1')
    end
  end

  context 'with a handle that does not resolve' do
    before { allow(client).to receive(:begin_authorization).and_raise(Atproto::Identity::Error, 'handle could not be resolved') }

    it 'sends them back with a message' do
      post member_bluesky_omniauth_authorize_path, params: { handle: 'nobody.example.com' }
      follow_redirect!

      expect(flash[:alert]).to eq(I18n.t('messages.bluesky_failed'))
    end
  end

  context 'without a handle' do
    it 'sends them back with a message' do
      post member_bluesky_omniauth_authorize_path

      expect(flash[:alert]).to eq(I18n.t('messages.bluesky_failed'))
    end
  end

  context 'when Bluesky sends them back with an error' do
    let(:description) { 'This request has expired' }

    before do
      allow(client).to receive(:begin_authorization).and_return(['https://auth.test/authorize', { 'state' => 's' }])
      post member_bluesky_omniauth_authorize_path, params: { handle: 'alice.bsky.social' }
      get member_bluesky_omniauth_callback_path, params: { error: 'access_denied', error_description: description }
    end

    it 'tells them it took too long when the request expired' do
      expect(flash[:alert]).to eq(I18n.t('messages.bluesky_expired'))
    end

    context 'when they declined' do
      let(:description) { 'User denied access' }

      it 'says Bluesky did not approve it' do
        expect(flash[:alert]).to eq(I18n.t('messages.bluesky_declined'))
      end
    end
  end
end
