# frozen_string_literal: true

require 'rails_helper'

describe MastodonClientService, type: :service do
  subject(:service) { described_class.new(resolver:, adapter: [:test, stubs]) }

  # VCR hooks into Faraday and refuses requests outside a cassette. These examples
  # stand in for the server with Faraday's own test adapter, so VCR is not wanted.
  around { |example| VCR.turned_off { example.run } }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:resolver) { class_double(Resolv, getaddresses: addresses) }
  let(:addresses) { ['93.184.216.34'] }
  let(:callback_url) { 'https://growstuff.example/members/auth/mastodon/callback' }
  let(:registration) { { client_id: 'new-id', client_secret: 'new-secret' } }
  let(:registration_status) { 200 }
  let(:registration_body) { registration.to_json }
  let(:registration_error) { nil }
  let(:sent) { [] }

  # Runs the lookup, ignoring a refusal, for examples about what happened on the way.
  def attempt(domain = 'mastodon.social')
    service.credentials_for(domain, callback_url)
  rescue described_class::Error
    nil
  end

  before do
    stubs.post('/api/v1/apps') do |env|
      raise registration_error if registration_error

      sent << Rack::Utils.parse_query(env.body)
      [registration_status, { 'Content-Type' => 'application/json' }, registration_body]
    end
  end

  describe '#credentials_for' do
    context 'with a client already stored for the server' do
      before do
        MastodonClient.create!(domain: 'mastodon.social', client_id: 'stored-id', client_secret: 'stored-secret',
                               redirect_uri: callback_url)
      end

      it 'returns the stored credentials' do
        expect(service.credentials_for('mastodon.social', callback_url)).to eq %w(stored-id stored-secret)
      end

      it 'does not ask the server again' do
        service.credentials_for('mastodon.social', callback_url)
        expect(sent).to be_empty
      end
    end

    context 'with a server we have not met' do
      it 'returns the credentials the server issued' do
        expect(service.credentials_for('mastodon.social', callback_url)).to eq %w(new-id new-secret)
      end

      it 'keeps them for next time' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to change(MastodonClient, :count).by(1)
      end

      it 'registers with the callback url' do
        service.credentials_for('mastodon.social', callback_url)
        expect(sent.first['redirect_uris']).to eq callback_url
      end

      it 'asks only for what it needs' do
        service.credentials_for('mastodon.social', callback_url)
        expect(sent.first['scopes']).to eq 'read:accounts'
      end

      it 'says where the site is' do
        service.credentials_for('mastodon.social', callback_url)
        expect(sent.first['website']).to eq 'https://growstuff.example/'
      end
    end

    context 'when the address was typed untidily' do
      it 'stores the server under its lowercase name' do
        service.credentials_for(' Mastodon.Social ', callback_url)
        expect(MastodonClient.last.domain).to eq 'mastodon.social'
      end
    end

    context 'when the stored client was registered for another callback url' do
      before do
        MastodonClient.create!(domain: 'mastodon.social', client_id: 'old-id', client_secret: 'old-secret',
                               redirect_uri: 'https://old.example/callback')
      end

      it 'registers again' do
        expect(service.credentials_for('mastodon.social', callback_url)).to eq %w(new-id new-secret)
      end

      it 'replaces the stored client rather than adding another' do
        expect { service.credentials_for('mastodon.social', callback_url) }.not_to change(MastodonClient, :count)
      end
    end

    context 'when the stored secret can no longer be read' do
      before do
        MastodonClient.create!(domain: 'mastodon.social', client_id: 'old-id', client_secret: 'old-secret', redirect_uri: callback_url)
        # What is left behind when the encryption keys have changed: something we can't decrypt.
        MastodonClient.update_all("client_secret = 'not something we encrypted'") # rubocop:disable Rails/SkipsModelValidations
      end

      it 'registers again' do
        expect(service.credentials_for('mastodon.social', callback_url)).to eq %w(new-id new-secret)
      end
    end

    ['', nil, 'localhost', 'mastodon.social/evil', 'user@mastodon.social', '1.2.3.4', 'mastodon.social:3000',
     'exa mple.com', 'https://mastodon.social'].each do |bad_domain|
      context "with #{bad_domain.inspect} for a server name" do
        it 'is refused' do
          expect { service.credentials_for(bad_domain, callback_url) }.to raise_error(described_class::Error)
        end

        it 'does not ask any server' do
          attempt(bad_domain)
          expect(sent).to be_empty
        end
      end
    end

    %w(10.0.0.5 127.0.0.1 169.254.169.254 192.168.1.1 ::1 fd00::1 ::ffff:10.0.0.5).each do |private_address|
      context "when the server resolves to #{private_address}" do
        let(:addresses) { [private_address] }

        it 'is refused' do
          expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /not a public server/)
        end
      end
    end

    context 'when the server resolves to a public and a private address' do
      let(:addresses) { ['93.184.216.34', '10.0.0.5'] }

      it 'is refused' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error)
      end
    end

    context 'when the server does not resolve' do
      let(:addresses) { [] }

      it 'is refused' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /does not exist/)
      end
    end

    context 'when the server will not register us' do
      let(:registration_status) { 422 }
      let(:registration_body) { '{"error":"nope"}' }

      it 'fails' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /422/)
      end

      it 'stores nothing' do
        attempt
        expect(MastodonClient.count).to eq 0
      end
    end

    context 'when the answer is not JSON' do
      let(:registration_body) { '<html>maintenance</html>' }

      it 'fails' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /unexpected answer/)
      end
    end

    context 'when the answer has no secret' do
      let(:registration_body) { { client_id: 'new-id' }.to_json }

      it 'fails' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /unexpected answer/)
      end
    end

    context 'when the server cannot be reached' do
      let(:registration_error) { Faraday::ConnectionFailed.new('connection refused') }

      it 'fails' do
        expect { service.credentials_for('mastodon.social', callback_url) }.to raise_error(described_class::Error, /Could not reach/)
      end
    end
  end
end
