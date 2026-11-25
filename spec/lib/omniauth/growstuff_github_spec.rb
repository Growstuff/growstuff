# frozen_string_literal: true

require 'rack/mock'
require_relative '../../../lib/omniauth/growstuff_github'

RSpec.describe OmniAuth::Strategies::GrowstuffGithub do
  subject(:strategy) { described_class.new(->(_env) { [200, {}, []] }, 'client-id', 'client-secret', path_prefix: '/members/auth') }

  let(:profile) { { 'id' => 123, 'login' => 'alice', 'name' => 'Alice', 'email' => 'public@example.com', 'avatar_url' => 'https://avatars.githubusercontent.com/u/123' } }

  describe '.enabled?' do
    subject(:enabled) { described_class.enabled? }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GROWSTUFF_GITHUB_CLIENT_ID').and_return('client-id')
      allow(ENV).to receive(:[]).with('GROWSTUFF_GITHUB_CLIENT_SECRET').and_return(secret)
    end

    context 'with both credentials' do
      let(:secret) { 'client-secret' }

      it('enables sign in') { expect(enabled).to be true }
    end

    context 'without a secret' do
      let(:secret) { nil }

      it('disables sign in') { expect(enabled).to be false }
    end

    context 'with a blank secret' do
      let(:secret) { ' ' }

      it('disables sign in') { expect(enabled).to be false }
    end

    context 'without a client ID' do
      let(:secret) { 'client-secret' }

      before { allow(ENV).to receive(:[]).with('GROWSTUFF_GITHUB_CLIENT_ID').and_return(nil) }

      it('disables sign in') { expect(enabled).to be false }
    end
  end

  describe '#info' do
    before { allow(strategy).to receive(:raw_info).and_return(profile) }

    it 'uses the stable numeric identity' do
      expect(strategy.uid).to eq '123'
    end

    it 'suggests the GitHub login name' do
      expect(strategy.info[:nickname]).to eq 'alice'
    end

    it 'displays the GitHub login rather than a mutable full name' do
      expect(strategy.info[:name]).to eq 'alice'
    end

    it 'imports the avatar' do
      expect(strategy.info[:image]).to eq profile['avatar_url']
    end

    it 'does not trust the public email for account matching' do
      expect(strategy.info).not_to have_key(:email)
    end
  end

  describe '#raw_info' do
    let(:token) { instance_double(OAuth2::AccessToken) }

    before do
      allow(strategy).to receive(:access_token).and_return(token)
      allow(token).to receive(:options).and_return({})
      allow(token).to receive(:get).with('/user', anything).and_return(double(parsed: profile))
    end

    it 'reads the authenticated public profile' do
      expect(strategy.raw_info).to eq profile
    end
  end

  describe '#credentials' do
    it 'does not expose access tokens to persistence or session data' do
      expect(strategy.credentials).to be_empty
    end
  end

  describe '#callback_url' do
    let(:url) { 'https://growstuff.example/members/auth/github/callback?code=private-code&state=state' }

    before do
      strategy.instance_variable_set(:@env, Rack::MockRequest.env_for(url, 'rack.session' => {}))
    end

    it 'excludes the callback query parameters' do
      expect(strategy.callback_url).to eq 'https://growstuff.example/members/auth/github/callback'
    end
  end

  describe '#request_phase' do
    let(:url) { 'https://growstuff.example/members/auth/github' }

    before do
      strategy.instance_variable_set(:@env, Rack::MockRequest.env_for(url, 'rack.session' => {}))
    end

    context 'with credentials configured' do
      before { allow(described_class).to receive(:enabled?).and_return(true) }

      let(:query) { Rack::Utils.parse_query(URI.parse(strategy.request_phase[1]['location']).query) }

      it 'redirects to GitHub' do
        expect(strategy.request_phase[1]['location']).to start_with('https://github.com/login/oauth/authorize?')
      end

      it 'does not request repository or email scopes' do
        expect(query['scope'].to_s).to be_empty
      end

      it 'includes a state for CSRF protection' do
        expect(query['state']).not_to be_empty
      end

      it 'uses the callback for this provider' do
        expect(query['redirect_uri']).to eq 'https://growstuff.example/members/auth/github/callback'
      end
    end

    context 'without credentials configured' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
        allow(strategy).to receive(:fail!).with(:not_configured).and_return(:failed)
      end

      it 'refuses to start authorization' do
        expect(strategy.request_phase).to eq :failed
      end
    end
  end

  describe '#callback_phase' do
    let(:session) { { 'omniauth.state' => 'expected-state' } }
    let(:url) { "https://growstuff.example/members/auth/github/callback?#{query}" }

    before do
      strategy.instance_variable_set(:@env, Rack::MockRequest.env_for(url, 'rack.session' => session))
      allow(strategy).to receive(:fail!).and_return(:failed)
    end

    context 'with an invalid state' do
      let(:query) { 'code=untrusted&state=wrong-state' }

      it 'rejects the callback before exchanging a token' do
        strategy.callback_phase
        expect(strategy).to have_received(:fail!).with(:csrf_detected, an_instance_of(OmniAuth::Strategies::OAuth2::CallbackError))
      end
    end

    context 'without a state' do
      let(:query) { 'code=untrusted' }

      it 'rejects the callback' do
        strategy.callback_phase
        expect(strategy).to have_received(:fail!).with(:csrf_detected, an_instance_of(OmniAuth::Strategies::OAuth2::CallbackError))
      end
    end

    context 'when authorization is declined' do
      let(:query) { 'error=access_denied&state=expected-state' }

      it 'reports the denial' do
        strategy.callback_phase
        expect(strategy).to have_received(:fail!).with('access_denied', an_instance_of(OmniAuth::Strategies::OAuth2::CallbackError))
      end
    end

    context 'with a valid authorization code and state' do
      let(:query) { 'code=valid-code&state=expected-state' }
      let(:token) { OAuth2::AccessToken.new(strategy.client, 'private-token') }

      before do
        allow(strategy).to receive(:build_access_token).and_return(token)
        allow(token).to receive(:get).with('/user', anything).and_return(instance_double(OAuth2::Response, parsed: profile))
        strategy.callback_phase
      end

      it 'passes the GitHub identity to the application' do
        expect(strategy.env['omniauth.auth'].uid).to eq '123'
      end

      it 'does not pass access tokens to the application session' do
        expect(strategy.env['omniauth.auth'].credentials).to be_empty
      end

      it 'does not pass public email to account matching' do
        expect(strategy.env['omniauth.auth'].info.email).to be_nil
      end
    end
  end
end
