# frozen_string_literal: true

require 'omniauth-mastodon'

module OmniAuth
  module Strategies
    #
    # omniauth-mastodon, but a mistyped or unusable server is a failed login, not a 500.
    #
    # The gem asks for credentials (our MastodonClientService) before OmniAuth's own
    # error handling starts, so anything it raises would otherwise escape as an exception.
    # `fail!` sends it to OmniauthCallbacksController#failure instead.
    #
    class GrowstuffMastodon < Mastodon
      # Only identity is needed: who is this account? That is verify_credentials.
      # Defined here, not in MastodonClientService, because the Devise initializer
      # needs it at boot and app/ classes can't be autoloaded that early.
      SCOPE = 'read:accounts'

      def request_phase
        super
      rescue ::MastodonClientService::Error => e
        fail!(:invalid_instance, e)
      end

      def callback_phase
        super
      rescue ::MastodonClientService::Error => e
        fail!(:invalid_instance, e)
      end

      private

      # Only the server matters: Mastodon asks whoever is logged in there to approve, so a
      # username typed here would be ignored. Take a bare server (mastodon.social), a pasted
      # address (https://mastodon.social/@alice), or the old you@mastodon.social, and hand the
      # upstream strategy "@server". It splits on @ and uses what follows the last one.
      def identifier
        server = super.to_s.sub(%r{\Ahttps?://}, '').split('/').first.to_s.split('@').last
        "@#{server}" if server.present?
      end
    end
  end
end
