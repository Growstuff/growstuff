# frozen_string_literal: true

module Atproto
  # The member's side of the AT Protocol OAuth dance: a pushed authorization
  # request with PKCE out, and a DPoP-bound code exchange back. We only want to
  # know who they are, so the tokens we are given are not kept.
  #
  # `begin_authorization` returns the URL to send them to plus a hash to keep in
  # the session; `complete` takes that hash back with the callback params.
  class OauthClient
    class Error < StandardError; end

    def initialize(config)
      @config = config
    end

    def begin_authorization(handle)
      identity = Identity.resolve(handle)
      server = authorization_server(identity.pds)
      dpop_key = Jws.generate_key
      state = SecureRandom.urlsafe_base64(24)
      verifier = SecureRandom.urlsafe_base64(48)

      request_uri, nonce = push_request(server, dpop_key, identity.handle, state, verifier)
      url = "#{server['authorization_endpoint']}?#{URI.encode_www_form(client_id: @config.client_id, request_uri:)}"
      session = { 'state' => state, 'verifier' => verifier, 'did' => identity.did, 'handle' => identity.handle,
                  'issuer' => server['issuer'], 'token_endpoint' => server['token_endpoint'],
                  'dpop_key' => dpop_key.to_pem, 'dpop_nonce' => nonce }
      [url, session]
    end

    # Returns { did:, handle: } for the account that approved us.
    def complete(session, params)
      raise Error, 'state mismatch' unless secure_equal?(session['state'], params['state'])
      raise Error, 'issuer mismatch' if params['iss'].present? && params['iss'] != session['issuer']
      raise Error, params['error_description'] || params['error'] if params['error'].present?
      raise Error, 'no code returned' if params['code'].blank?

      token = exchange_code(session, params['code'])
      raise Error, 'token is for a different account' unless token['sub'] == session['did']
      raise Error, 'identity was not granted' unless token['scope'].to_s.split.include?(ClientConfig::SCOPE)

      { did: session['did'], handle: session['handle'] }
    end

    private

    def authorization_server(pds)
      resource = Http.get_json("#{pds}/.well-known/oauth-protected-resource")
      issuer = Array(resource['authorization_servers']).first
      server = Http.get_json("#{issuer}/.well-known/oauth-authorization-server")
      raise Error, 'authorization server issuer mismatch' unless server['issuer'] == issuer

      missing = %w(authorization_endpoint token_endpoint pushed_authorization_request_endpoint).select { |k| server[k].blank? }
      raise Error, "authorization server lacks #{missing.join(', ')}" if missing.any?

      server
    rescue Http::Error => e
      raise Error, e.message
    end

    def push_request(server, dpop_key, handle, state, verifier)
      form = {
        client_id: @config.client_id, response_type: 'code', redirect_uri: @config.redirect_uri,
        scope: ClientConfig::SCOPE, state:, login_hint: handle,
        code_challenge: Jws.encode(OpenSSL::Digest::SHA256.digest(verifier)), code_challenge_method: 'S256'
      }
      body, nonce = dpop_post(server['pushed_authorization_request_endpoint'], server['issuer'], dpop_key, form)
      raise Error, 'no request_uri returned' if body['request_uri'].blank?

      [body['request_uri'], nonce]
    end

    def exchange_code(session, code)
      form = {
        grant_type: 'authorization_code', code:, redirect_uri: @config.redirect_uri,
        code_verifier: session['verifier'], client_id: @config.client_id
      }
      body, = dpop_post(session['token_endpoint'], session['issuer'], OpenSSL::PKey::EC.new(session['dpop_key']), form,
                        nonce: session['dpop_nonce'])
      body
    end

    # POSTs with a DPoP proof and our client assertion. Servers demand a nonce
    # they choose, so a use_dpop_nonce answer gets one retry. Returns the body and
    # the latest nonce.
    def dpop_post(url, issuer, dpop_key, form, nonce: nil)
      2.times do
        form = form.merge(client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                          client_assertion:      @config.client_assertion(issuer))
        body, headers, ok = Http.post_form(url, form, headers: { 'DPoP' => dpop_proof(dpop_key, url, nonce) })
        nonce = headers.transform_keys(&:downcase)['dpop-nonce'] || nonce
        return [body, nonce] if ok
        raise Error, body['error_description'] || body['error'].to_s unless body['error'] == 'use_dpop_nonce'
      end
      raise Error, 'server kept rejecting the DPoP nonce'
    rescue Http::Error => e
      raise Error, e.message
    end

    def dpop_proof(key, url, nonce)
      payload = { jti: SecureRandom.hex(16), htm: 'POST', htu: url, iat: Time.now.to_i }
      payload[:nonce] = nonce if nonce
      Jws.sign(key, { typ: 'dpop+jwt', alg: 'ES256', jwk: Jws.public_jwk(key).except(:kid) }, payload)
    end

    def secure_equal?(expected, actual)
      expected.present? && actual.present? && ActiveSupport::SecurityUtils.secure_compare(expected, actual)
    end
  end
end
