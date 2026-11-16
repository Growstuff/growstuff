# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    # Identity only: no repository permissions or private email access.
    class GrowstuffGithub < OAuth2
      option :name, 'github'
      option :client_options, site: 'https://api.github.com',
                              authorize_url: 'https://github.com/login/oauth/authorize',
                              token_url: 'https://github.com/login/oauth/access_token'

      def self.enabled?
        %w(GROWSTUFF_GITHUB_CLIENT_ID GROWSTUFF_GITHUB_CLIENT_SECRET).all? { |key| !ENV[key].to_s.strip.empty? }
      end

      uid { raw_info.fetch('id').to_s }

      # A public profile email is not proof of ownership. Do not pass it to the
      # signup action, which can match existing members by email.
      info do
        { nickname: raw_info['login'], name: raw_info['login'], image: raw_info['avatar_url'] }
      end

      # The token is only needed to fetch the identity, not after sign-in.
      def credentials
        {}
      end

      def request_phase
        return fail!(:not_configured) unless self.class.enabled?

        super
      end

      def raw_info
        access_token.options[:mode] = :header
        @raw_info ||= access_token.get('/user', headers: { 'Accept' => 'application/vnd.github+json',
                                                         'User-Agent' => 'Growstuff' }).parsed
      end

      # Keep the redirect URI identical during authorization and token exchange;
      # the callback's code and state are not part of the registered URL.
      def callback_url
        full_host + callback_path
      end
    end
  end
end
