# frozen_string_literal: true

require 'rails_helper'

describe Atproto::OauthClient do
  subject(:client) { described_class.new(config) }

  let(:config) { Atproto::ClientConfig.new('https://growstuff.test', key: Atproto::Jws.generate_key) }
  let(:identity) { instance_double(Atproto::Identity, did: 'did:plc:abcdefghijklmnopqrstuvwx', handle: 'alice.bsky.social', pds: 'https://pds.test') }
  let(:server) do
    {
      'issuer'                                => 'https://auth.test',
      'authorization_endpoint'                => 'https://auth.test/authorize',
      'token_endpoint'                        => 'https://auth.test/token',
      'pushed_authorization_request_endpoint' => 'https://auth.test/par'
    }
  end

  before do
    allow(Atproto::Identity).to receive(:resolve).with('alice.bsky.social').and_return(identity)
    allow(Atproto::Http).to receive(:get_json).with('https://pds.test/.well-known/oauth-protected-resource')
      .and_return('authorization_servers' => ['https://auth.test'])
    allow(Atproto::Http).to receive(:get_json).with('https://auth.test/.well-known/oauth-authorization-server').and_return(server)
    allow(Atproto::Http).to receive(:post_form).with('https://auth.test/par', anything, anything)
      .and_return([{ 'request_uri' => 'urn:par:1' }, { 'DPoP-Nonce' => 'n1' }, true])
  end

  describe '#begin_authorization' do
    subject(:result) { client.begin_authorization('alice.bsky.social') }

    it 'sends the member to the authorization endpoint with the pushed request' do
      expect(result.first).to eq("https://auth.test/authorize?client_id=#{CGI.escape(config.client_id)}&request_uri=urn%3Apar%3A1")
    end

    it 'remembers the server nonce for the token request' do
      expect(result.last).to include('dpop_nonce' => 'n1', 'did' => identity.did)
    end

    context 'when the authorization server will not take pushed requests' do
      before { server.delete('pushed_authorization_request_endpoint') }

      it 'raises' do
        expect { result }.to raise_error(described_class::Error, /pushed_authorization_request_endpoint/)
      end
    end

    context 'when the server asks for a DPoP nonce first' do
      before do
        allow(Atproto::Http).to receive(:post_form).with('https://auth.test/par', anything, anything)
          .and_return([{ 'error' => 'use_dpop_nonce' }, { 'dpop-nonce' => 'n2' }, false],
                      [{ 'request_uri' => 'urn:par:2' }, { 'dpop-nonce' => 'n3' }, true])
      end

      it 'retries with the nonce it was given' do
        expect(result.last).to include('dpop_nonce' => 'n3')
      end
    end
  end

  describe '#complete' do
    let(:session) { client.begin_authorization('alice.bsky.social').last }
    let(:params) { { 'state' => session['state'], 'code' => 'abc', 'iss' => 'https://auth.test' } }
    let(:token) { { 'sub' => identity.did, 'scope' => 'atproto', 'access_token' => 'x' } }

    before do
      allow(Atproto::Http).to receive(:post_form).with('https://auth.test/token', anything, anything).and_return([token, {}, true])
    end

    it 'returns the account that approved' do
      expect(client.complete(session, params)).to eq(did: identity.did, handle: 'alice.bsky.social')
    end

    context 'with a different state' do
      it 'raises' do
        expect { client.complete(session, params.merge('state' => 'other')) }.to raise_error(described_class::Error, /state/)
      end
    end

    context 'when the token is for another account' do
      let(:token) { { 'sub' => 'did:plc:zzzzzzzzzzzzzzzzzzzzzzzz', 'scope' => 'atproto' } }

      it 'raises' do
        expect { client.complete(session, params) }.to raise_error(described_class::Error, /different account/)
      end
    end

    context 'when the issuer is not the one we started with' do
      it 'raises' do
        expect { client.complete(session, params.merge('iss' => 'https://evil.test')) }.to raise_error(described_class::Error, /issuer/)
      end
    end
  end
end
