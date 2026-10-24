# frozen_string_literal: true

# Growstuff is an OAuth 2 provider, so apps such as the Android app can sign
# members in without ever seeing their password. An app is a public client that
# signs in with the authorisation code flow and PKCE. An admin adds an app at
# /oauth/applications, with "Confidential" unticked.
Doorkeeper.configure do
  orm :active_record

  # Members sign in with Devise. Someone not signed in is sent to do that first,
  # and comes back to finish authorising the app.
  resource_owner_authenticator do
    current_member || warden.authenticate!(scope: :member)
  end

  # Only admins say which apps may use the API.
  admin_authenticator do
    warden.authenticate!(scope: :member)
    head :forbidden unless current_member.role?(:admin)
  end

  grant_flows %w(authorization_code)

  # A public app must prove it is the one that asked for the code (PKCE).
  force_pkce

  # Reading is the default; changing things needs `write` as well.
  default_scopes :read
  optional_scopes :write
  enforce_configured_scopes

  # Short-lived access tokens, with a refresh token that is replaced each time it
  # is used. Tokens are kept hashed, so a copy of the database cannot be used to
  # sign in.
  access_token_expires_in 1.hour
  use_refresh_token
  hash_token_secrets

  # Tokens are only accepted in the Authorization header, never in an address.
  access_token_methods :from_bearer_authorization
end
