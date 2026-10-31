# frozen_string_literal: true

require 'omniauth'

module OmniAuth
  module Strategies
    # Sign in with Bluesky (AT Protocol OAuth). The member types a handle, which
    # decides where the authorization server is, so the request phase is POSTed
    # a `handle` rather than redirecting to a fixed URL. All the protocol work
    # lives in Atproto::OauthClient.
    class Bluesky
      include OmniAuth::Strategy

      uid { @identity[:did] }

      info do
        { name: @identity[:handle], nickname: @identity[:handle], handle: @identity[:handle] }
      end

      credentials { {} }

      def request_phase
        handle = request.params['handle']
        return fail!(:missing_handle) if handle.blank?

        url, state = client.begin_authorization(handle)
        session['atproto'] = state
        redirect url
      rescue Atproto::Identity::Error, Atproto::OauthClient::Error => e
        fail!(:invalid_credentials, e)
      end

      def callback_phase
        pending = session.delete('atproto')
        return fail!(:session_expired) unless pending

        @identity = client.complete(pending, request.params)
        super
      rescue Atproto::OauthClient::Error => e
        fail!(:invalid_credentials, e)
      end

      private

      def client
        Atproto::OauthClient.new(Atproto::ClientConfig.new(full_host))
      end
    end
  end
end
