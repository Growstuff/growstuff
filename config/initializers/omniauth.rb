# frozen_string_literal: true

require Rails.root.join('lib/omniauth/strategies/bluesky')

# Devise sets this when it draws its routes. Set here too, so the first request
# after boot doesn't reach the middleware before the prefix is known and fall
# through to Devise's "Authentication passthru" 404.
OmniAuth.config.path_prefix = '/members/auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :flickr, ENV.fetch('GROWSTUFF_FLICKR_KEY', nil), ENV.fetch('GROWSTUFF_FLICKR_SECRET', nil), scope: 'read'
  provider :bluesky
end
