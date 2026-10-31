# frozen_string_literal: true

class Authentication < ApplicationRecord
  belongs_to :member

  # Providers a member can sign in or sign up with, and whether each is set up
  # here. To add another, register it with OmniAuth, add it to Member's
  # omniauth_providers, and give it a partial in app/views/authentications/sign_in/.
  SIGN_IN_PROVIDERS = {
    'bluesky' => -> { Atproto::ClientConfig.enabled? }
  }.freeze

  # Providers that identify someone without telling us an email address.
  EMAIL_OPTIONAL_PROVIDERS = %w(bluesky).freeze

  def self.enabled_sign_in_providers
    SIGN_IN_PROVIDERS.select { |_provider, enabled| enabled.call }.keys
  end
end
