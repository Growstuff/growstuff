# frozen_string_literal: true

module Atproto
  # Growstuff's identity as an AT Protocol OAuth client. The client_id is the URL
  # of a metadata document we serve ourselves, and we authenticate with an ES256
  # key held in GROWSTUFF_ATPROTO_PRIVATE_KEY (see `rake atproto:generate_key`).
  class ClientConfig
    SCOPE = 'atproto'
    METADATA_PATH = '/oauth/client-metadata.json'
    CALLBACK_PATH = '/members/auth/bluesky/callback'

    def self.private_key
      pem = ENV.fetch('GROWSTUFF_ATPROTO_PRIVATE_KEY', nil)
      OpenSSL::PKey::EC.new(pem.gsub('\n', "\n")) if pem.present?
    end

    # Sign-in with Bluesky stays hidden until a key is configured.
    def self.enabled?
      private_key.present?
    end

    def initialize(base_url, key: self.class.private_key)
      @base_url = base_url.chomp('/')
      @key = key
    end

    def client_id
      @base_url + METADATA_PATH
    end

    def redirect_uri
      @base_url + CALLBACK_PATH
    end

    def public_jwk
      Jws.public_jwk(@key).merge(alg: 'ES256', use: 'sig')
    end

    def metadata
      {
        client_id:,
        client_name: 'Growstuff',
        client_uri: @base_url,
        redirect_uris: [redirect_uri],
        scope: SCOPE,
        grant_types: %w(authorization_code),
        response_types: %w(code),
        application_type: 'web',
        token_endpoint_auth_method: 'private_key_jwt',
        token_endpoint_auth_signing_alg: 'ES256',
        dpop_bound_access_tokens: true,
        jwks: { keys: [public_jwk] }
      }
    end

    # Proves to the authorization server that this request comes from us.
    def client_assertion(issuer)
      Jws.sign(@key, { alg: 'ES256', typ: 'JWT', kid: public_jwk[:kid] },
               iss: client_id, sub: client_id, aud: issuer, jti: SecureRandom.hex(16), iat: Time.now.to_i)
    end
  end
end
