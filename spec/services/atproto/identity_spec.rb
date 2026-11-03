# frozen_string_literal: true

require 'rails_helper'

describe Atproto::Identity do
  let(:did) { 'did:plc:abcdefghijklmnopqrstuvwx' }
  let(:document) do
    { 'id' => did, 'alsoKnownAs' => ['at://alice.bsky.social'],
      'service' => [{ 'id' => '#atproto_pds', 'type' => 'AtprotoPersonalDataServer', 'serviceEndpoint' => 'https://pds.test' }] }
  end

  before do
    allow(Atproto::Http).to receive(:get).with('https://alice.bsky.social/.well-known/atproto-did').and_return("#{did}\n")
    allow(Atproto::Http).to receive(:get_json).with("https://plc.directory/#{did}").and_return(document)
  end

  describe '.resolve' do
    subject(:identity) { described_class.resolve('@Alice.bsky.social') }

    it('finds the DID') { expect(identity.did).to eq(did) }
    it('finds the PDS') { expect(identity.pds).to eq('https://pds.test') }

    context 'with a handle that has no domain' do
      subject(:identity) { described_class.resolve('alice') }

      it 'assumes bsky.social' do
        expect(identity.handle).to eq('alice.bsky.social')
      end
    end

    context 'when the DID document names a different handle' do
      before { document['alsoKnownAs'] = ['at://mallory.example'] }

      it 'raises' do
        expect { identity }.to raise_error(described_class::Error, /does not match/)
      end
    end

    context 'when the handle domain does not answer' do
      before do
        allow(Atproto::Http).to receive(:get).and_raise(Atproto::Http::Error)
        allow(Atproto::Http).to receive(:get_json).with(/resolveHandle/).and_return('did' => did)
      end

      it 'falls back to the Bluesky resolver' do
        expect(identity.did).to eq(did)
      end
    end

    context 'with something that is not a handle' do
      it 'raises without making a request' do
        expect { described_class.resolve('http://169.254.169.254/') }.to raise_error(described_class::Error, /not a valid handle/)
      end
    end
  end
end
