# frozen_string_literal: true

require Rails.root.join('lib/omniauth/strategies/bluesky')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :flickr, ENV.fetch('GROWSTUFF_FLICKR_KEY', nil), ENV.fetch('GROWSTUFF_FLICKR_SECRET', nil), scope: 'read'
  provider :bluesky
end
