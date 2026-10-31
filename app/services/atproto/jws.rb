# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'json'

module Atproto
  # Just enough JOSE for AT Protocol OAuth: ES256 signed tokens (DPoP proofs and
  # client assertions) and the matching public JWK.
  module Jws
    module_function

    def generate_key
      OpenSSL::PKey::EC.generate('prime256v1')
    end

    def sign(key, header, payload)
      signing_input = "#{encode(header.to_json)}.#{encode(payload.to_json)}"
      "#{signing_input}.#{encode(raw_signature(key, signing_input))}"
    end

    # The public half as a JWK, with a key id derived from its thumbprint.
    def public_jwk(key)
      point = key.public_key.to_octet_string(:uncompressed)
      jwk = { kty: 'EC', crv: 'P-256', x: encode(point[1, 32]), y: encode(point[33, 32]) }
      jwk.merge(kid: thumbprint(jwk))
    end

    def thumbprint(jwk)
      canonical = { crv: jwk[:crv], kty: jwk[:kty], x: jwk[:x], y: jwk[:y] }.to_json
      encode(OpenSSL::Digest::SHA256.digest(canonical))
    end

    def encode(bytes)
      Base64.urlsafe_encode64(bytes, padding: false)
    end

    # JWS wants the bare r || s, not the DER structure OpenSSL produces.
    def raw_signature(key, input)
      der = key.sign('SHA256', input)
      r, s = OpenSSL::ASN1.decode(der).value.map { |n| n.value.to_s(2).rjust(32, "\0") }
      r + s
    end
    private_class_method :raw_signature, :thumbprint
  end
end
