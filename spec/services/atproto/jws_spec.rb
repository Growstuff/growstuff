# frozen_string_literal: true

require 'rails_helper'

describe Atproto::Jws do
  let(:key) { described_class.generate_key }
  let(:token) { described_class.sign(key, { alg: 'ES256' }, sub: 'x') }

  it 'signs with a 64 byte raw signature' do
    expect(Base64.urlsafe_decode64(token.split('.').last).bytesize).to eq(64)
  end

  it 'produces a signature the public key verifies' do
    header, payload, signature = token.split('.')
    raw = Base64.urlsafe_decode64(signature)
    der = OpenSSL::ASN1::Sequence.new(raw.unpack('a32a32').map { |n| OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(n, 2)) }).to_der

    expect(key.verify('SHA256', der, "#{header}.#{payload}")).to be(true)
  end

  it 'publishes only the public half in the JWK' do
    expect(described_class.public_jwk(key).keys).to contain_exactly(:kty, :crv, :x, :y, :kid)
  end
end
